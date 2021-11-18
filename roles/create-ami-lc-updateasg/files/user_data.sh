#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sleep 60
echo "Agent Connection Testing Started." >> /tmp/trend.out
/opt/ds_agent/dsa_control -r >> /tmp/trend.out
sleep 20
echo "Agent Connection Esatblished." >> /tmp/trend.out
/etc/init.d/ds_agent restart >> /tmp/trend.out
sleep 60
echo "agent Restarted" >> /tmp/trend.out
echo "Policy about to apply" >> /tmp/trend.out
/opt/ds_agent/dsa_control -a dsm://agents.deepsecurity.trendmicro.com:443/ "tenantID:B3B5AEF3-5D45-7C3F-088D-EC99A7F2CBD7" "token:3A857D11-2757-B2C0-278B-B489CFE52AAF" "policyid:801" >> /tmp/trend.out
echo "Agent Policy Applied" >> /tmp/trend.out