#!/bin/bash
# Author: shmakovpn <shmakovpn@krw.rzd>
# Date: 2019-08-05
source ~/db_conf.sh

# begin command line arguments
for arg in "$@"; do
    if [[ $arg =~ '-h' ]]; then
        echo "Use '$0 [-h] md5 in_file_name out_file_name'"
        echo "    md5 md5sum of 1024 bytes of the file"
        echo "    in_file_name name of the file"
        echo "    out_file_name name of the file in server"
        echo "    [-h] show this help message"
        exit 0
    fi
done
if [[ -z $1 ]]; then
    echo "Error. A md5 command line argument does not present. See '$0 -h'"
    exit 1
fi
if [[ -z $2 ]]; then
    echo "Error. An in_file_name command line argument does not present. See '$0 -h'"
    exit 1
fi
if [[ -z $3 ]]; then
    echo "Error. An out_file_name command line argument does not present. See '$0 -h'"
    exit 1
fi
# end command line arguments

# returns a fake md5sum value
fake_md5 {
    echo 
}

hello() {
    echo "hello ${1}"
}

hello "mudaki"

exit 0

md5=$(uuid | md5sum | sed -re "s/[ \-]*$//")
fin='fin'
fout='fout'
MD5='ab9a38410139c2455cb075ebcf7db66a'

COUNT2=`psql -c "select count(md5) from load_status where md5='${MD5}' and status=2 limit 1" | tail -n 3 | head -n 1 | sed 's/[^0-9]//g'`
#echo "md5=${md5}"
echo "count=${COUNT}"
if [[ ${COUNT2} -eq 1 ]]; then
    echo "alread copyed"
else
    COUNT1=`psql -c "select count(md5) from load_status where md5='${MD5}' and status=1 limit 1" | tail -n 3 | head -n 1 | sed 's/[^0-9]//g'`
    if [[ ${COUNT1} -eq 1 ]]; then
        echo "continue copying"
        OUT_FILE_NAME=`psql -c "select out_file_name from load_status where md5='${MD5}' and status=1 limit 1" | tail -n 3 | head -n 1 | sed 's/^\s*//'`
        echo "out file name ='${OUT_FILE_NAME}'"
    fi
fi
#psql -c "INSERT INTO load_status (md5, in_file_name, out_file_name, status) VALUES ('${md5}', '${fin}', '${fout}', 1)"
