#!/bin/bash
set -ex
export PATH=~/.local/bin:$PATH # This line will be temporary no need actually, this is in my local to identify aws cli command to work
ecr_destination_aws_account=$2
mircroservice_name_from_manifest=$3
destination_account_image_repo_name=$4
version_from_manifest=$5
env_name=$6
cross_account_role_name_from_destination_account=$7
region=$8
sns_topic=$9
if [[ "$version_from_manifest" == "" ]]; then 
  echo "Mark Tag is not required, we dont have version from manifest file, given is $version_from_manifest"
  exit 0
fi
# source ecr login
{
aws sns publish --message "Deployment started in $env_name for $mircroservice_name_from_manifest version:$version_from_manifest" --subject "Cync microservice Deployment to $env_name environment-started" --topic-arn "arn:aws:sns:$region:$ecr_destination_aws_account:$sns_topic" --region $region &&
echo 'copy for ' &&
staging_account_login="$(eval $(aws ecr get-login --region $region --registry-ids $ecr_destination_aws_account --no-include-email))" &&
sleep 2 &&
echo "staging account login status ${staging_account_login}" &&
MANIFEST=$(aws ecr batch-get-image --region $region --registry-id $ecr_destination_aws_account --repository-name $destination_account_image_repo_name --image-ids imageTag=$env_name --query 'images[].imageManifest' --output text) &&
aws ecr batch-delete-image --region $region --registry-id $ecr_destination_aws_account --repository-name $destination_account_image_repo_name --image-ids imageTag=$env_name &&
MANIFEST=$(aws ecr batch-get-image --region $region --registry-id $ecr_destination_aws_account --repository-name $destination_account_image_repo_name --image-ids imageTag=$version_from_manifest --query 'images[].imageManifest' --output text) &&
aws ecr put-image --region $region --registry-id $ecr_destination_aws_account --repository-name $destination_account_image_repo_name --image-tag $env_name --image-manifest "$MANIFEST"
# aws sns publish --message "Deployment success in $env_name for $mircroservice_name_from_manifest version:$IMAGE_TAG" --subject "Cync microservice Deployment to $env_name environment-success" --topic-arn "arn:aws:sns:$region:$ecr_destination_aws_account:$sns_topic" --region $region
} || {
        echo "Deployment failed for $mircroservice_name_from_manifest" &&
        aws sns publish --message "Deployment failed in $env_name for $mircroservice_name_from_manifest version:$IMAGE_TAG" --subject "Cync microservice Deployment to $env_name environment-failed" --topic-arn "arn:aws:sns:$region:$ecr_destination_aws_account:$sns_topic" --region $region &&
        exit 1
}
 
