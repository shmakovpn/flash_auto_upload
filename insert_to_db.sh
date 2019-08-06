#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-05
source ~/db_conf.sh

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
    echo "Error. An in_file command line argument does not present. See '$0 -h'"
    exit 1
fi
# end command line arguments

if [[ ! -f $1 ]]; then
    echo "Error. '$1' is not a file"
    exit 1
fi
if [[ ! -r $1 ]]; then
    echo "Error. '$1' cannot be read"
    exit 1
fi

# calc MD5 check sum of the file
MD5=`head -c 1024 $1 | md5sum | sed -re "s/[ \-]*$//"`
IN_FILE_NAME=`basename $1`
if [[ -z $2 ]]; then
    OUT_FILE_NAME=${IN_FILE_NAME}
else
    OUT_FILE_NAME=$2
fi

# int count(int status)
# returns count of records with status
count() {
    psql -c "SELECT COUNT(md5) from load_status where md5='${MD5}' and status=$1 limit 1" | tail -n 3 | head -n 1 | sed 's/^\s*//'
}

# status = 1 file is copied
# status = 2 file successfully copied
# status = 3 file deleted since no longer needed
if [[ `count 2` -eq 1 ]]; then
    echo "File alread copyed"
    exit 0
fi
if [[ `count 3` -eq 1 ]]; then
    echo "The deleted since no longer needed"
    exit 0
fi 
if [[ `count 1` -eq 1 ]]; then
    echo "The file is copied"
else
    # insert info about a new file
    if [[ ! `psql -c "INSERT INTO load_status (md5, in_file_name, out_file_name, status) VALUES ('${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1)"` =~ 'INSERT 0 1'  ]]; then
        logger -p local.err "Error. '$0' INSERT '${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1 failed"
        echo "Error. '$0' INSERT '${MD5}', '${IN_FILE_NAME}', '${OUT_FILE_NAME}', 1 failed" >&2
        exit 1
    fi
fi

exit 0


    COUNT1=`psql -c "select count(md5) from load_status where md5='${MD5}' and status=1 limit 1" | tail -n 3 | head -n 1 | sed 's/[^0-9]//g'`
    if [[ ${COUNT1} -eq 1 ]]; then
        echo "continue copying"
        OUT_FILE_NAME=`psql -c "select out_file_name from load_status where md5='${MD5}' and status=1 limit 1" | tail -n 3 | head -n 1 | sed 's/^\s*//'`
        echo "out file name ='${OUT_FILE_NAME}'"
    fi
#psql -c "INSERT INTO load_status (md5, in_file_name, out_file_name, status) VALUES ('${md5}', '${fin}', '${fout}', 1)"
