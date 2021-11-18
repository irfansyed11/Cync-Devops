#!/bin/bash
AppName=$1
RepositoryBranch=$2
CodePipelineName=$(cat Staging_pipelines.json | jq -r .$1.Pipeline)
StackName=$(cat Staging_pipelines.json | jq -r .$1.Stack)

if [ "$#" -eq 2 ]
then
        echo "Updating Stack ${StackName} with ${RepositoryBranch} branch and triggering pipeline ${CodePipelineName}"
        ParameterKey=$(aws cloudformation describe-stacks --stack-name ${StackName} --region us-east-1 | jq -r '.Stacks[].Parameters[].ParameterKey')
        Stack="aws cloudformation update-stack --stack-name ${StackName} --region us-east-1 --use-previous-template --capabilities CAPABILITY_NAMED_IAM --parameters "
        outvar=""
        Parameters=""
        for i in $ParameterKey
        do
                if [ $i == RepositoryBranch ]
                then
                        Parameters="ParameterKey=$i,ParameterValue=${RepositoryBranch} "
                else
                        Parameters="ParameterKey=$i,UsePreviousValue=true "
                fi
                outvar="$Stack$Parameters"
                Stack="$outvar"
        done
        $outvar
        sleep 20
       aws codepipeline start-pipeline-execution --name ${CodePipelineName} --region us-east-1
else
        if [ "$#" -eq 1 ]
        then
                echo "Triggering Pipeline ${CodePipelineName}"
                aws codepipeline start-pipeline-execution --name ${CodePipelineName} --region us-east-1
        fi
fi
