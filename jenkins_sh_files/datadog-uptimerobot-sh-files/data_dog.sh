#!/bin/bash
set -ex

query="tag:$tag"
echo "given tag: $query"
echo "given action: $action"
response=$(curl -X GET \
-H "DD-API-KEY: ${api_key}" \
-H "DD-APPLICATION-KEY: ${app_key}" \
"https://api.datadoghq.com/api/v1/monitor/search?query=${query}"| jq '.monitors[].id')
echo "list of monitor ids to $action"
echo $response
for monitor_id in $response
do
# Mute a monitor
mute_response=$(curl -X POST \
-H "Content-type: application/json" \
-H "DD-API-KEY: ${api_key}" \
-H "DD-APPLICATION-KEY: ${app_key}" \
"https://api.datadoghq.com/api/v1/monitor/${monitor_id}/$action")
echo "$action response for $monitor_id"
echo $mute_repsonse
done

