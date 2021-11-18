#!/bin/bash
set -x
owner=$1
instanceid=$2
instancename=$3
regionname=$4
ami_tags=$5
noreboot=$6
waitforami=$7
TIMESTAMP=`date "+%d%b%Y-%H%M%S"`
max_retry=10
counter=0
until
latest_Ami_state=$(aws ec2 describe-images --owners ${owner} --region $regionname --filters Name=name,Values=${instancename}-* --query 'sort_by(Images, &CreationDate)[-1].[State]' --output 'text')
if [[ $latest_Ami_state != "pending" ]]; then
   if [[ $noreboot == "no" ]]; then
           ami=$(aws ec2 create-image --instance-id $instanceid --name "$instancename-$TIMESTAMP" --region $regionname --reboot --output 'text')
           aws ec2 create-tags --resources $ami --region $regionname --tags $ami_tags
   else
         ami=$(aws ec2 create-image --instance-id $instanceid --name "$instancename-$TIMESTAMP" --region $regionname --output 'text')
         aws ec2 create-tags --resources $ami --region $regionname --tags $ami_tags
   fi #noreboot if ended
   echo "$ami"
     if [[ $waitforami == "yes" ]]; then
         aws ec2 wait image-available --image-ids $ami --region $regionname
     fi  #wait for ami ifended
else
  #echo "Ami is already inprogress"
  echoo
fi  #latest_Ami_state if ended

do
   sleep 60
   [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
   ((counter++))
   #echo "Trying again. Try #$counter"

done
