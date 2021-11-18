#!/bin/bash
echo \<h1\>Deployment status of $1\<\/h1\>
echo \<table cellpadding="6" cellspacing="6" width="100%" style="border: 1px;"\>
echo \<tr\>
echo \<td\>Deployment-ID\<\/td\>
echo \<td\>Deployment-STATUS\<\/td\>
echo \<td\>StartTime\<\/td\>
echo \<td\>EndTime\<\/td\>
echo \<td\>ApplicationName\<\/td\>
echo \<\/tr\>
while read line; do
    echo \<tr\>
    for item in $line;do
        echo \<td\>$item\<\/td\>
    done
    echo \<\/tr\>
done
echo \<\/table\>
