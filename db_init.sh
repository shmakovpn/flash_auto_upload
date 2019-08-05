#!/bin/bash
source ~/db_conf.sh

for arg in "$@"; do
    if [[ ${arg} =~ '-c' ]]; then
        psql -c "DROP TABLE IF EXISTS load_status"
    fi
done

psql -c "CREATE TABLE IF NOT EXISTS load_status (\
             md5 UUID NOT NULL PRIMARY KEY,\
             in_file_name CHARACTER VARYING(200) NOT NULL,\
             out_file_name CHARACTER VARYING(200) NOT NULL,\
             status INTEGER NOT NULL DEFAULT 1\
         )"
echo "result=$?"

