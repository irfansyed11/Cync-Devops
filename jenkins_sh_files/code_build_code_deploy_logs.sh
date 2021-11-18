#!/bin/bash
#set -ex
#aws codepipeline start-pipeline-execution --region us-east-1 --name ${CodePipelineName}
#sleep 20
BuildID=$(aws codepipeline get-pipeline-state --region us-east-1 --name ${CodePipelineName} | jq -r '.stageStates[1].actionStates[].latestExecution.externalExecutionId')
echo "${BuildID}"
LoggroupName=$( aws codebuild batch-get-builds --region us-east-1 --ids ${BuildID} | jq -r '.builds[].logs.groupName')
LogStreamName=$(aws codebuild batch-get-builds --region us-east-1 --ids ${BuildID} | jq -r '.builds[].logs.streamName')
echo "${LoggroupName}"
echo "${LogStreamName}"
echo "*****************################=> Below are CodeBuild logs <=################*****************"

result=$(aws logs get-log-events \
    --start-from-head \
    --log-group-name=${LoggroupName} \
    --log-stream-name=${LogStreamName} \
    --region=us-east-1)
nextToken=$(echo $result | jq -r .nextForwardToken)

echo ${result} | jq -r ".events[].message"

while [ -n "$nextToken" ]; do
    #echo ${nextToken}
    current_status=$(aws codebuild batch-get-builds --region us-east-1 --ids ${BuildID} | jq -r '.builds[].buildStatus')
    result=$(aws logs get-log-events \
        --start-from-head \
        --log-group-name=${LoggroupName} \
        --log-stream-name=${LogStreamName} \
        --region=us-east-1 \
        --next-token="${nextToken}")
   #echo "cstatus ${current_status}"

    echo ${result} | jq -r ".events[].message"
    nextToken=$(echo ${result} | jq -r .nextForwardToken)

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "IN_PROGRESS" && ${current_status} == "SUCCEEDED" ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      break
    fi

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "IN_PROGRESS" && ${current_status} == "FAILED" ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      exit
    fi
done

echo "*****************################ Below are CodeDeploy logs ################*****************"
sleep 60
DeployInfo=$(aws codepipeline get-pipeline-state --region us-east-1 --name ${CodePipelineName})
DeployType=`echo $DeployInfo | jq -r '.stageStates[2].stageName'`
if [[ $DeployType == "LambdaDeploy" ]]; then
cloudwatch_url=`echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.externalExecutionUrl'`
exact_log_group_name=$(echo $cloudwatch_url | awk -F"group=" '{print $2}' | sed -e "s/%252F/\//g")
#echo "log name $exact_log_group_name"
exact_log_stream_name=$(aws logs describe-log-streams --log-group-name $exact_log_group_name --region us-east-1 --order-by=LastEventTime --descending | jq -r '.logStreams[0].logStreamName')
#echo "stream name $exact_log_stream_name"
current_status=$(echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.status')
if [[ $current_status != "InProgress" ]]; then
aws logs filter-log-events --log-group-name $exact_log_group_name --log-stream-name $exact_log_stream_name --region us-east-1 | jq -r '.events[].message'
else
LoggroupName="$exact_log_group_name"
LogStreamName="$exact_log_stream_name"
#start_time=$(aws deploy get-deployment --deployment-id $DeployID --region  us-east-1 | jq -r ".deploymentInfo.createTime")
#trimmed_start_time="${start_time//./}"
#end_time=$(aws deploy get-deployment --deployment-id $DeployID --region  us-east-1 | jq -r ".deploymentInfo.completeTime")
result=$(aws logs get-log-events \
    --start-from-head \
    --log-group-name=${LoggroupName} \
    --log-stream-name=${LogStreamName} \
    --region=us-east-1)
nextToken=$(echo $result | jq -r .nextForwardToken)

echo ${result} | jq -r ".events[].message"

while [ -n "$nextToken" ]; do
    #echo ${nextToken}
    DeployInfo=$(aws codepipeline get-pipeline-state --region us-east-1 --name ${CodePipelineName})
    current_status=$(echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.status')
    result=$(aws logs get-log-events \
        --start-from-head \
        --log-group-name=${LoggroupName} \
        --log-stream-name=${LogStreamName} \
        --region=us-east-1 \
        --next-token="${nextToken}")
   #echo "cdeploy status ${current_status}"
   #echo "condition status $(echo ${result} | jq -e '.events == []')"
    echo ${result} | jq -r ".events[].message"
    nextToken=$(echo ${result} | jq -r .nextForwardToken)

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "InProgress" && ${current_status} == "Succeeded"  ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      break
    fi

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "InProgress" && ${current_status} == "Failed" ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      exit
    fi
done
fi

else
DeployID=`echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.externalExecutionId'`
echo "${DeployID}"
splitted_deploy_id=$(echo $DeployID | awk -F"-" '{print $2}')
current_status=$(echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.status')
if [[ $current_status != "InProgress" ]]; then
echo "code deploy not in inprogress status $current_status"
aws logs filter-log-events --log-group-name NDS-CYNC-STAGING-Ansible-Jumphost-New-Lg --log-stream-name i-0967a21d2c8913fa6-ansible-deployment --filter-pattern ${splitted_deploy_id} --region us-east-1 | jq -r '.events[].message'
else
LoggroupName='NDS-CYNC-STAGING-Ansible-Jumphost-New-Lg'
LogStreamName='i-0967a21d2c8913fa6-ansible-deployment'
start_time=$(aws deploy get-deployment --deployment-id $DeployID --region  us-east-1 | jq -r ".deploymentInfo.createTime")
trimmed_start_time="${start_time//./}"
end_time=$(aws deploy get-deployment --deployment-id $DeployID --region  us-east-1 | jq -r ".deploymentInfo.completeTime")
result=$(aws logs get-log-events \
    --start-from-head \
    --log-group-name=${LoggroupName} \
    --log-stream-name=${LogStreamName} \
    --start-time=${trimmed_start_time} \
    --region=us-east-1)
nextToken=$(echo $result | jq -r .nextForwardToken)

echo ${result} | jq -r ".events[].message"

while [ -n "$nextToken" ]; do
    #echo ${nextToken}
    DeployInfo=$(aws codepipeline get-pipeline-state --region us-east-1 --name ${CodePipelineName})
    current_status=$(echo $DeployInfo | jq -r '.stageStates[2].actionStates[].latestExecution.status')
    result=$(aws logs get-log-events \
        --start-from-head \
        --log-group-name=${LoggroupName} \
        --log-stream-name=${LogStreamName} \
        --start-time=${trimmed_start_time} \
        --region=us-east-1 \
        --next-token="${nextToken}")
   #echo "cdeploy status ${current_status}"
   #echo "condition status $(echo ${result} | jq -e '.events == []')"
    echo ${result} | jq -r ".events[].message"
    nextToken=$(echo ${result} | jq -r .nextForwardToken)

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "InProgress" && ${current_status} == "Succeeded"  ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      break
    fi

    if [[ $(echo ${result} | jq -e '.events == []') == "true" && $current_status != "InProgress" && ${current_status} == "Failed" ]]; then
      echo "No more logs found(pipeline already completed) scenario"
      exit
    fi
done

fi # code deploy current_status if
fi # deploytype(codedeploy/lambda deploy) if
echo "The End"
