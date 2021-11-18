#!/bin/bash
set -ex
export PATH=~/.local/bin:$PATH # This line will be temporary no need actually, this is in my local to identify aws cli command to work
mircroservice_name_from_manifest=$2
ecs_cluster_name_from_manifest=$3
destination_aws_account=$4
cross_account_role_name_from_destination_account=$5
envname=$6
image_tag=$7
region=$8
sns_topic=$9

rm -f credentials.json
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
{
# aws sns publish --message "Deployment started in $envname for $mircroservice_name_from_manifest version:$image_tag" --subject "Cync microservice Deployment to $envname environment-started" --topic-arn "arn:aws:sns:$region:$destination_aws_account:$sns_topic" --region $region &&
aws sts assume-role --role-arn arn:aws:iam::$destination_aws_account:role/$cross_account_role_name_from_destination_account --role-session-name $cross_account_role_name_from_destination_account | jq .Credentials >> credentials.json &&

export AWS_ACCESS_KEY_ID=$(jq '.AccessKeyId' credentials.json | sed 's/"//g') &&
export AWS_SECRET_ACCESS_KEY=$(jq '.SecretAccessKey' credentials.json | sed 's/"//g') &&
export AWS_SESSION_TOKEN=$(jq '.SessionToken' credentials.json | sed 's/"//g') &&

running_tasks=$(eval aws ecs list-tasks --cluster=$ecs_cluster_name_from_manifest --family=$mircroservice_name_from_manifest --region $region | jq .taskArns[]) &&
for i in $running_tasks
do 
   echo "Going to stop ecs task of $i" &&
   aws ecs stop-task --region $region --cluster $ecs_cluster_name_from_manifest --task $(eval basename $i) &&
   echo "task stopped of $i"
done 
aws sns publish --message "Deployment success in $envname for $mircroservice_name_from_manifest version:$image_tag" --subject "Cync microservice Deployment to $envname environment-success" --topic-arn "arn:aws:sns:$region:$destination_aws_account:$sns_topic" --region $region
} || {
       echo "Deployment failed for $mircroservice_name_from_manifest" &&
       aws sns publish --message "Deployment failed in $envname for $mircroservice_name_from_manifest version:$image_tag" --subject "Cync microservice Deployment to $envname environment-failed" --topic-arn "arn:aws:sns:$region:$destination_aws_account:$sns_topic" --region $region &&
       exit 1 
}


