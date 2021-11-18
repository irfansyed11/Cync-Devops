#!/bin/bash
set -ex
action=$1
RuleName=$2
for i in ${RuleName}
do
 aws events --region us-east-1 $action-rule --name ${i}
done
