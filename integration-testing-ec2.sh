#!/bin/bash
echo "Integration Testing EC2"

aws --version

Data=$(aws ec2 describe-instances)
echo "Data - "$Data
URL=$(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "dev-deploy") | .PublicDnsName')
echo "URL Data - "$URL

if [[ "$URL" != '' ]]; then
    http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:5000/health)
        echo "http_code - "$http_code
    news_data_length=$(curl -s "http://52.215.46.205:5000/" | wc -c)
        echo "news_data - "$news_data_length

    if [[ "$http_code" -eq 200 && "$news_data_length" -gt 30000 ]];
        then
            echo "Integration Testing EC2 Passed"
        else
            echo "Integration Testing EC2 Failed"
            exit 1
        fi
    else
        echo "Integration Testing EC2 Failed"
        exit 1    
fi;

