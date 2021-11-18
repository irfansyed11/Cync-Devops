#!/bin/bash
AppName=$1
RepositoryBranch=$2
QATESTINGTRIGGERENVVALUE=$3
CodePipelineName=$(cat Staging_pipelines.json | jq -r .$AppName.Pipeline)
StackName=$(cat Staging_pipelines.json | jq -r .$AppName.Stack)

if [[ "$AppName" == "STAGING_BaseROR" ||  "$AppName" == "STAGING_CashAppROR_MS" ]]
then
        echo "Updating Stack ${StackName} with ${RepositoryBranch} branch and triggering pipeline ${CodePipelineName}"
        ParameterKey=$(aws cloudformation describe-stacks --stack-name ${StackName} --region us-east-1 | jq -r '.Stacks[].Parameters[].ParameterKey')
        Stack="aws cloudformation update-stack --stack-name ${StackName} --region us-east-1 --use-previous-template --capabilities CAPABILITY_NAMED_IAM --parameters "
        outvar=""
        Parameters=""

        for i in $ParameterKey
        do
            if [ "$RepositoryBranch" != "" ]        # when both RepositoryBranch and testing need to be updated
            then
                if [ $i == RepositoryBranch ]
                then
                        Parameters="ParameterKey=$i,ParameterValue=${RepositoryBranch} "
                elif [ $i == QATESTINGTRIGGERENVVALUE ]
                then
                        Parameters="ParameterKey=$i,ParameterValue=${QATESTINGTRIGGERENVVALUE} "
                else
                        Parameters="ParameterKey=$i,UsePreviousValue=true "
                fi
           else [ "$RepositoryBranch" == "" ]       # when only testing need to be updated
                if [ $i == QATESTINGTRIGGERENVVALUE ]
                then
                        Parameters="ParameterKey=$i,ParameterValue=${QATESTINGTRIGGERENVVALUE} "
                else
                        Parameters="ParameterKey=$i,UsePreviousValue=true "
                fi
           fi
           outvar="$Stack$Parameters"
           Stack="$outvar"
        done
           $outvar
        sleep 20
          echo "Triggering Pipeline ${CodePipelineName}"
          aws codepipeline start-pipeline-execution --name ${CodePipelineName} --region us-east-1
else
        ./StackUpdate_PipelineTrigger.sh $AppName $RepositoryBranch
fi
