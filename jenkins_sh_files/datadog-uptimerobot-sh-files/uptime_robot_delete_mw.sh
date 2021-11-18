#!/bin/bash
set -ex

api_key="$(aws secretsmanager --region us-east-1 get-secret-value --secret-id NDS-CYNC-STAGING-UpTimeRobot | jq -r '.SecretString' | awk -F "\"" '{print $4}')"
present_date=$(date +"%Y%m%d")

for i in $given_mw_id_and_name
        do
                   mw_id_number=$(echo $i | awk -F"-" '{print $1}')
                   mw_id_date=$(echo $i | grep -o -E '[0-9]{8}')
                if [ "$mw_id_date" != "$present_date" ]
                then
                        echo "Deleting maintanance window: $i "
                        ########### BLOCK TO DELETE MAINTANINCE WINDOW INTO EACH MONITOR'S ###############
response=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" -d "api_key=$api_key&format=json&id=$mw_id_number" "https://api.uptimerobot.com/v2/deleteMWindow")
echo $response
                fi
        done
