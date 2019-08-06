#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-05
source ~/db_conf.sh
source ~/rsync_conf.sh

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "Use '$0 [-h] in_file [out_file_name]'"
        echo "    in_file  path to the file"
        echo "    [out_file_name] name of the file in server"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    logger -sp local0.err "'$0'. Error. A first command line argument does not present. See '$0 -h'"
    exit 1
fi
# end command line arguments

if [[ ! -f $1 ]]; then
    logger -sp local0.err "'$0'. Error. First argument '$1' is not a file"
    exit 1
fi
if [[ ! -r $1 ]]; then
    logger -sp local0.err "'$0'. Error. First argument '$1' cannot be read"
    exit 1
fi

# calc MD5 check sum of the file
MD5=`head -c 1024 $1 | md5sum | sed -re "s/[ \-]*$//"`
IN_FILE=$1
IN_FILE_NAME=`basename $1`
if [[ -z $2 ]]; then
    OUT_FILE_NAME=${IN_FILE_NAME}
else
    OUT_FILE_NAME=$2
fi

# int count(int status)
# returns count of records with status
_count() {
    psql -tc "SELECT COUNT(md5) from load_status WHERE md5='${MD5}' and status=$1 limit 1" | head -n 1 | sed 's/^\s*//'
}

_rsync() {
    OUT_PATH=`echo ${OUT_FILE} | sed -re 's/[^\/]*$//'`
    OUT_PATH_ARR=(${OUT_PATH//\// })
    OUT_PATH_AGG=''
    OUT_FILE_NAME=`echo ${OUT_FILE} | sed -re 's/^(.*\/)*//'`
    for i in "${OUT_PATH_ARR[@]}"; do
        echo "i=${i}"
        RSYNC_STATUS=`rsync /dev/null rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_PATH_AGG}${i}/ 2>&1`
        if [[ $? -ne 0 ]]; then
            logger -sp local0.err "'$0'. Error rsync could not create directory '${OUT_PATH_AGG}${i}/': ${RSYNC_STATUS}"
            exit 1
        fi
        OUT_PATH_AGG="${OUT_PATH_AGG}${i}/"
    done
    #echo "rsync --append ${IN_FILE} rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_FILE} 2>&1"
    RSYNC_STATUS=`rsync --append ${IN_FILE} rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_FILE} 2>&1`
    if [[ $? -eq 0 ]]; then
        PSQL_STATUS=`psql -c "UPDATE load_status SET status=2 WHERE md5='${MD5}'"` 
        if [[ ${PSQL_STATUS} =~ 'UPDATE 1' ]]; then
            MSG="File ${MD5} ${IN_FILE} to ${OUT_FILE} copied successfully"
            echo ${MSG}
            logger -p local0.info ${MSG}
        else
            MSG="Error. DB. Could not UPDATRE status to 2 atfer file ${MD5} ${IN_FILE} to ${OUT_FILE} copied successfully: ${PSQL_STATUS}"
            echo ${MSG}
            logger -p local0.err ${MSG}
        fi
    else
        echo "File ${MD5} ${IN_FILE} to ${OUT_FILE} copying failed: ${RSYNC_STATUS}"
        logger -p local0.err "File ${MD5} ${IN_FILE} to ${OUT_FILE} copying failed: ${RSYNC_STATUS}"
    fi
}

# status = 1 file is copied
# status = 2 file successfully copied
# status = 3 file deleted since no longer needed
if [[ `_count 2` -eq 1 ]]; then
    echo "File alread copyed"
    exit 0
fi
if [[ `_count 3` -eq 1 ]]; then
    echo "The deleted since no longer needed"
    exit 0
fi 
if [[ `_count 1` -eq 1 ]]; then
    echo "The file is copied"
    OUT_FILE=`psql -tc "SELECT TO_CHAR(begin_ts, 'YYYY/MM/DD/')||out_file_name FROM load_status WHERE md5='{$MD5}' LIMIT 1" | head -n 1 | sed 's/^\s*//'`
    _rsync
    exit 0
else
    # insert info about a new file
    PSQL_STATUS=`psql -c "INSERT INTO load_status (md5, in_file_name, out_file_name, status) VALUES ('${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1)" 2>&1`
    if [[ ! ${PSQL_STATUS} =~ 'INSERT 0 1'  ]]; then
        MSG="Error. DB. '$0' INSERT '${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1 failed: ${PSQL_STATUS}"
        logger -p local0.err ${MSG}
        echo ${MSG}
        exit 1
    else
        echo "Copy a new file"
        OUT_FILE="$(date +%Y/%m/%d)/${OUT_FILE_NAME}"
        _rsync
        exit 0
    fi
fi

exit 0


