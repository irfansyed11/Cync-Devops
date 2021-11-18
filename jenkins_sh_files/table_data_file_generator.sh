#!/bin/bash
#set -ex
AppName=$1
app_name=$(cat Staging_pipelines.json | jq -r .$1.codedeploy_application_name)
deploy_group_name=$(cat Staging_pipelines.json | jq -r .$1.deployment_group_name)
start_time=$2
end_time=$3
status=$4

rm -rf table_data

generate_report() {
  echo "inside another function $trigger_text"
  deployments_info=$(aws deploy batch-get-deployments --region us-east-1 --deployment-ids $trigger_text | jq -r '.deploymentsInfo | sort_by(.createTime|todate) | reverse| map([.deploymentId,.status,"\(.createTime|todate)","\(.completeTime|todate)",.applicationName] | join(" "))' >> table_data)
  sed -i 's/[][,"]//g' table_data | tr -s ' '

  ./html_output_file_generator.sh "$AppName" < table_data > deployment_query_output.html
 cat table_data
}

if [ $status == all ]
then
       deployment_ids=($(aws deploy list-deployments --region us-east-1 --application-name $app_name --deployment-group-name $deploy_group_name --create-time-range start="$start_time"T00:00:00Z,end="$end_time"T23:59:59Z | jq '.deployments[]'  | sed 's/\"//g'))
else
      deployment_ids=($(aws deploy list-deployments --region us-east-1 --application-name $app_name --deployment-group-name $deploy_group_name --include-only-statuses=$status --create-time-range start="$start_time"T00:00:00Z,end="$end_time"T23:59:59Z | jq '.deployments[]'  | sed 's/\"//g'))
fi
     echo  $deployment_ids

if [ "$deployment_ids" != "" ]
then
     echo ${#deployment_ids[@]}
     trigger_text=""
     incrementor=1
     for i in ${deployment_ids[@]}
     do  
        trigger_text="${trigger_text} ${i}"
      if [[ $((incrementor%25)) -eq 0 ]];then
        generate_report trigger_text
        trigger_text=""
      elif [[ $incrementor -eq ${#deployment_ids[@]} ]]; then
        generate_report trigger_text
      fi
       incrementor=$(expr $incrementor + 1)
     done
else
  echo "Deployments_not_found_for_given_time_period" > table_data
   ./html_output_file_generator.sh "$AppName" < table_data > deployment_query_output.html
fi

