#!/bin/bash
#set -ex
ENV=$1
project_list=$2
echo "For $ENV generating report of $project_list"
Projectfunction() {
      cd /home/ubuntu/cync-automation-scripts/$project
      pwd
      rm -rf Reports/*
      rm -rf message.txt
      echo "Syncing Git code is started"
      git reset --hard HEAD~1
      git fetch && git rebase origin/master
      git log -1
      echo "Syncing Git code is done"
      /opt/apache-maven-3.6.1/bin/mvn clean test -Dtest.env=$ENV
      Directory=$(ls Reports/ | grep html | head -n 1 | tr "." "\n" | head -n 1)
      echo "dir name is $Directory"
      mkdir $Directory
      if [[ $? -ne 0 ]];then
         aws sns publish --topic-arn "arn:aws:sns:us-east-1:798793081579:Cync-Deployment-Notification"  --region us-east-1 --subject $ENV-$project --message "Failed generating report"
         exit 1
      fi
      zip -r ./$Directory/reports.zip ./Reports/.
      Reports=$(ls $Directory)
      if [ $project == cash_application_revamp ]
       then
          verionID=$(curl https://$ENV.cyncsoftware.com/api/cash-application-v2/v1/version)
       else
          verionID=$(curl https://$ENV.cyncsoftware.com/version.html)
      fi
      echo "Test reports for the version $verionID" > message.txt

     if [ $ENV == postuat ]
       then
             S3_bucket=prestaging-cync-artifacts
       else
             S3_bucket=staging-cync-artifacts
     fi 
                         ####################### Uploading to S3 bucket #######################
aws s3 cp $Directory/ s3://$S3_bucket/QAtestingreports/$project/$Directory --recursive
                         #################### Generating object URL ############################
      for report in $Reports
       do
          reportURL=$(aws s3 presign s3://$S3_bucket/QAtestingreports/$project/$Directory/$report --expires-in 604800)
          echo "${reportURL}" >> message.txt
       done
                        ################### SNS Notification ############################
aws sns publish --topic-arn "arn:aws:sns:us-east-1:798793081579:Cync-Deployment-Notification"  --region us-east-1 --subject $ENV-$project --message file://message.txt
      rm -rf $Directory
}

for project in $project_list
do
   Projectfunction $ENV $project
done
