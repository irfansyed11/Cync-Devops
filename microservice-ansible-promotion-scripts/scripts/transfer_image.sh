#!/bin/bash
# 
export PATH=~/.local/bin:$PATH # This line will be temporary no need actually
# source ecr login
source_account_login="$(eval sudo $(aws ecr get-login --region us-east-1 --registry-ids 546124439885))"
sleep 2
echo "source login status ${source_account_login}"
sudo docker pull 546124439885.dkr.ecr.us-east-1.amazonaws.com/mdn-repo-1:initial
sudo docker tag 546124439885.dkr.ecr.us-east-1.amazonaws.com/mdn-repo-1:initial 202771655335.dkr.ecr.us-east-1.amazonaws.com/mdn-repo-1:initial
destination_account_login="$(eval sudo $(aws ecr get-login --region us-east-1 --registry-ids 202771655335))"
sleep 2
echo "destination login status ${destination_account_login}"
sudo docker push 202771655335.dkr.ecr.us-east-1.amazonaws.com/mdn-repo-1:initial
