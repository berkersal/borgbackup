#!/bin/bash

. automated_backup_env.sh
required_vars=(DIRECTORIES_TO_BACKUP HEALTHCHECKS_URL)  
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set."
        exit 1
    fi
done

ANY_FAILURE=0
curl -m 10 --retry 5 $HEALTHCHECKS_URL/start

for dir in "${DIRECTORIES_TO_BACKUP[@]}"; do
    if [ -d "$dir" ]; then
        dir_name=$(basename "$dir")
        backup_start_date=$(date +"%Y-%m-%d_%H-%M-%S")
        mkdir -p "./logs/$dir_name/info"
        mkdir -p "./logs/$dir_name/debug"
        ./backup.sh "$dir" > "./logs/$dir_name/info/$backup_start_date.log" 2> "./logs/$dir_name/debug/$backup_start_date.log"
        if [ $? -eq 0 ]; then
            msg="Backup of $dir_name completed successfully."
            echo "$msg"
            curl -m 10 --retry 5 --data-raw "$msg" $HEALTHCHECKS_URL/log
        else
            msg="Backup of $dir_name failed. Check logs for details."
            echo "$msg"
            curl -m 10 --retry 5 --data-raw "$msg" $HEALTHCHECKS_URL/log
            ANY_FAILURE=1
        fi
    else
        msg="Directory $dir does not exist, skipping."
        echo "$msg"
        curl -m 10 --retry 5 --data-raw "$msg" $HEALTHCHECKS_URL/log
        ANY_FAILURE=1
    fi
done

if [ $ANY_FAILURE -eq 0 ]; then
    msg="All backups completed successfully."
    echo "$msg"
    curl -m 10 --retry 5 --data-raw "$msg" $HEALTHCHECKS_URL
else
    msg="Some backups failed. Check logs for details."
    echo "$msg"
    curl -m 10 --retry 5 --data-raw "$msg" $HEALTHCHECKS_URL/fail
fi
