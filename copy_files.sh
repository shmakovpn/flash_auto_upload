#!/bin/bash
# Author: shmakovpn <shmakovpn@yandex.ru>
# Date: 2019-08-05

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "This script copies files from a removable media to server"
        echo "Use '$0 [-h] disk_name'"
        echo "    disk_name the name of mounted removable drive (like sdb1, sdc1, ..)"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    logger -sp local0.err "'$0'. Error. A first command line argument does not present. See '$0 -h' 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
if [[ ! $1 =~ ^sd[b-z][1-9]$ ]]; then
    logger -sp local0.err "'$0'. Error: wrong command line argument '$1'. Must be sd[b-z][1-9] 0161392a-b4d1-11e9-ba84-080027858e30"
    exit 1
fi
# end command line arguments

PWD=`dirname $0`
if [[ ! $PWD =~ ^\/ ]]; then
    PWD=`pwd`"/"`echo ${PWD} | sed -re 's/^\.\///'`
fi

source ${PWD}/conf/db_conf.sh
source ${PWD}/conf/rsync_conf.sh
source ${PWD}/conf/mount_conf.sh

# begin subs
# int count(int status)
# returns count of records with status
_count() {
    PSQL_STATUS=`psql -tc "SELECT COUNT(md5) from load_status WHERE md5='${MD5}' and status=$1 limit 1" | head -n 1 | sed 's/^\s*//' 2>&1`
    if [[ $? -ne 0 ]]; then
        logger -sp "'$0'. Error DB. Could not select count(md5): ${PSQL_STATUS}. 0161392a-b4d1-11e9-ba84-080027858e30"
        COPY_ERROR=1  # sets copy error flag
    fi
    echo ${PSQL_STATUS}
}

_rsync() {
    OUT_PATH=`echo ${OUT_FILE} | sed -re 's/[^\/]*$//'`
    OUT_PATH_ARR=(${OUT_PATH//\// })
    OUT_PATH_AGG=''
    OUT_FILE_NAME=`echo ${OUT_FILE} | sed -re 's/^(.*\/)*//'`
    for i in "${OUT_PATH_ARR[@]}"; do
        RSYNC_STATUS=`rsync /dev/null rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_PATH_AGG}${i}/ 2>&1`
        if [[ $? -ne 0 ]]; then
            logger -sp local0.err "'$0'. Error rsync could not create directory '${OUT_PATH_AGG}${i}/': ${RSYNC_STATUS}. 0161392a-b4d1-11e9-ba84-080027858e30"
            COPY_ERROR=1  # sets copy error flag
            break
        fi
        OUT_PATH_AGG="${OUT_PATH_AGG}${i}/"
    done
    #echo "rsync --append ${IN_FILE} rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_FILE} 2>&1"
    RSYNC_STATUS=`rsync --append-verify ${IN_FILE} rsync://${RSYNC_HOST}/${RSYNC_PATH}${OUT_FILE} 2>&1`
    if [[ $? -eq 0 ]]; then
        PSQL_STATUS=`psql -c "UPDATE load_status SET status=2,end_ts=now() WHERE md5='${MD5}'"` 
        if [[ ${PSQL_STATUS} =~ 'UPDATE 1' ]]; then
            logger -sp local0.info "'$0'. File ${MD5} ${IN_FILE} to ${OUT_FILE} copied successfully. 0161392a-b4d1-11e9-ba84-080027858e30"
        else
            logger -sp local0.err "'$0'. Error. DB. Could not UPDATRE status to 2 atfer file ${MD5} ${IN_FILE} to ${OUT_FILE} copied successfully: ${PSQL_STATUS}. 0161392a-b4d1-11e9-ba84-080027858e30"
        fi
    else
        logger -sp local0.err "'$0'. File ${MD5} ${IN_FILE} to ${OUT_FILE} copying failed: ${RSYNC_STATUS}. 0161392a-b4d1-11e9-ba84-080027858e30"
        COPY_ERROR=1  # sets copy error flag
    fi
}
# end subs

while [[ 1 ]]; do
    FILES_LIST=`find ${MOUNT_DIR}/$1 | grep -Pi '\.vdi$'`
    FILES_ARR=(${FILES_LIST//\n/ })
    COPY_ERROR=0  # copy error flag
    if [[ ! -b /dev/$1 ]]; then
        logger -sp local0.err "'$0'. Error. Flash device '$1' was removed while searching for files. 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
    for IN_FILE in "${FILES_ARR[@]}"; do
        if [[ ! -f ${IN_FILE} ]]; then
            logger -sp local0.err "'$0'. Error.'${IN_FILE}' is not a file. 0161392a-b4d1-11e9-ba84-080027858e30"
            continue
        fi
        if [[ ! -f ${IN_FILE} ]]; then
            logger -sp local0.err "'$0'. Error. '${IN_FILE}' cannot be read. 0161392a-b4d1-11e9-ba84-080027858e30"
            continue
        fi
        # calc MD5 check sum of the file
        MD5=`head -c 1024 ${IN_FILE} | md5sum | sed -re "s/[ \-]*$//"`
        IN_FILE_NAME=`echo ${IN_FILE} | sed -re 's/^(.*\/)*//'`
        OUT_FILE_NAME=${IN_FILE_NAME}  # reserved for future, if an out file will have a different name than a source file
        
        # status = 1 file is copied
        # status = 2 file successfully copied
        # status = 3 file deleted since no longer needed
        if [[ `_count 2` -eq 1 ]]; then
            logger -sp local0.info "File '${IN_FILE_NAME}' md5='${MD5}' alread copyed. 0161392a-b4d1-11e9-ba84-080027858e30"
            continue
        fi
        if [[ `_count 3` -eq 1 ]]; then
            logger -sp local0.info "File '${IN_FILE_NAME}' md5='${MD5}' no longer needed. 0161392a-b4d1-11e9-ba84-080027858e30"
            continue
        fi
        if [[ `_count 1` -eq 1 ]]; then
            logger -sp local0.info "File '${IN_FILE_NAME}' md5='${MD5}' continue copying. 0161392a-b4d1-11e9-ba84-080027858e30"
            OUT_FILE=`psql -tc "SELECT TO_CHAR(begin_ts, 'YYYY/MM/DD/')||out_file_name FROM load_status WHERE md5='{$MD5}' LIMIT 1" | head -n 1 | sed 's/^\s*//'`
            _rsync
            continue
        else
            logger -sp local0.info "File '${IN_FILE_NAME}' md5='${MD5}' new copying. 0161392a-b4d1-11e9-ba84-080027858e30"
            PSQL_STATUS=`psql -c "INSERT INTO load_status (md5, in_file_name, out_file_name, status) VALUES ('${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1)" 2>&1`
            if [[ ! ${PSQL_STATUS} =~ 'INSERT 0 1'  ]]; then
                logger -sp local0.err "Error. DB. '$0' INSERT '${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1 failed: ${PSQL_STATUS}. 0161392a-b4d1-11e9-ba84-080027858e30"
                COPY_ERROR=1
                continue
            else
                OUT_FILE="$(date +%Y/%m/%d)/${OUT_FILE_NAME}"
                _rsync
                continue
            fi
        fi
    done
    
    # redo if rsync error
    if [[ COPY_ERROR -eq 0 ]]; then
        break
    fi
    logger -sp local0.err "'$0'. There are copying errors. Retrying after 10 sec. 0161392a-b4d1-11e9-ba84-080027858e30"
    sleep 10
done

# unmount drive
mount -l | grep -Pi "${MOUNT_DIR}/$1" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    logger -sp local0.info "'$0' all files successfully copied. Unmounting '${MOUNT_DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
    umount ${MOUNT_DIR}/$1
    mount -l | grep -Pi "${MOUNT_DIR}/$1" > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        logger -p local0.err "'$0' Error: could not unmount directory '${MOUNT_DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi
if [[ -d ${MOUNT_DIR}/$1 ]]; then
    logger -sp local0.info "'$0'. Removing directory '${MOUNT_DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
    rmdir ${MOUNT_DIR}/$1
    if [[ -d ${MOUNT_DIR}/$1 ]]; then
        logger -p local0.err "'$0' Error: could not remove '${MOUNT_DIR}/$1'. 0161392a-b4d1-11e9-ba84-080027858e30"
        exit 1
    fi
fi

exit 0


