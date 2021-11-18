#!/bin/bash
set -x
max_retry=5
counter=0
api_key="$(aws secretsmanager --region us-east-1 get-secret-value --secret-id NDS-CYNC-STAGING-UpTimeRobot | jq -r '.SecretString' | awk -F "\"" '{print $4}')"
friendly_name="$2"
duration="$1"
env_name="$3"
app_name="$4"
until 
echo "Given friendly name $friendly_name, Given duration $duration"
rm -f uptime_details.json
filter_by_name=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" -d "api_key=$api_key&format=json&mwindows=1&search=$friendly_name" "https://api.uptimerobot.com/v2/getMonitors")
status=`echo $filter_by_name | jq .stat`
if [[ $status == '"fail"' ]]; then
echo "filter query api failed"
echoo
else
	filter_by_name=`echo $filter_by_name | jq '[.monitors[]|{id: .id, name: .friendly_name, existing_mw_ids: [.mwindows[].id]}]' >> uptime_details.json`
	########### BLOCK TO CREATE MAINTANINCE WINDOW ###############
	unix_timestamp=$(date +%s)
	echo $unix_timestamp
	new_timestamp=`expr $unix_timestamp + 60`
	user_readable_timestamp=`date +'%Y%m%d-%H:%M' -d "@$new_timestamp"`
	# Block to create MW
	newly_created_mw_call=$(curl -X POST -H "Cache-Control: no-cache" -H "Content-Type: application/x-www-form-urlencoded" -d "api_key=$api_key&format=json&friendly_name=AUTO-MW-$env_name-$app_name-$user_readable_timestamp&type=1&start_time=$new_timestamp&duration=$duration" "https://api.uptimerobot.com/v2/newMWindow")
	echo "new window call $newly_created_mw_call"
	status=`echo $newly_created_mw_call | jq .stat`
       if [[ $status != '"fail"' ]]; then
        newly_created_mw_id=`echo $newly_created_mw_call | jq '.mwindow.id'`
	echo "mw id is $newly_created_mw_id"


	########### BLOCK TO ADD MAINTANINCE WINDOW INTO EACH MONITOR'S ###############
	jq -c '.[]' uptime_details.json | while read i; do
	    mname=`echo $i | jq '.name'`
	    mid=`echo $i | jq '.id'`
	    existing_mw_ids=`echo $i | jq '.existing_mw_ids'`
	    trimmed_existing_mw_ids=$(echo $existing_mw_ids | sed -e "s/, /\-/g" | sed -e "s/\\[ /\ /g" | sed -e "s/ \\]/\ /g")
	    trimmed_existing_mw_ids=${trimmed_existing_mw_ids// /}
	    if [[ "${#trimmed_existing_mw_ids}" -gt 2 ]]; then
	    echo "having more"
	    trimmed_existing_mw_ids+="-$newly_created_mw_id"
	    else
	    echo "having only one"
	    trimmed_existing_mw_ids="$newly_created_mw_id"
	    fi
	    echo "Doing MW for $mname, monitor_id is $mid, MW_id is $newly_created_mw_id, existing MW_IDS $proper_ids"
	    response=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" -d "api_key=$api_key&format=json&id=$mid&mwindows=$trimmed_existing_mw_ids" "https://api.uptimerobot.com/v2/editMonitor")
	   echo $response
	done
	else
	  echo "New maintenance window creation failed"
	  echoo
	fi
fi

do
   sleep 10
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   ((counter++))
   echo "Trying again. Try #$counter"

done

########### BLOCK TO DELETE MAINTANINCE WINDOW INTO EACH MONITOR'S ###############
#response=$(curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Cache-Control: no-cache" -d "api_key=$api_key&format=json&id=$newly_created_mw_id" "https://api.uptimerobot.com/v2/deleteMWindow")
#echo $response
