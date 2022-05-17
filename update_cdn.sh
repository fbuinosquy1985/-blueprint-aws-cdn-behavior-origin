#!/bin/bash
#====================================================================================================================
#Script that adds a origin and behavior to a cloudfront distribution , only for Load Balancers for the moment
#====================================================================================================================
: ${1?"How to use: $0 CLOUDFRONT_ID DOMAIN_URL DOMAIN_PATH"}
: ${2?"How to use: $0 CLOUDFRONT_ID DOMAIN_URL DOMAIN_PATH"}
: ${3?"How to use: $0 CLOUDFRONT_ID DOMAIN_URL DOMAIN_PATH"}

CDN_ID=$1            #E3554BHOW3RXY2
DOMAIN_NAME=$2       #"aac5e1e3235cc4c028de730c26369163-d8052e4acdbbae74.elb.us-east-1.amazonaws.com"
SHORT_DOMAIN_NAME=$3 #crm-uat-prod

export PATH=/home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
sudo apk add --update-cache python3 python3-dev py-pip build-base curl
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py
pip install awscli --upgrade
/usr/local/bin/aws

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=3
  local delay=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "================================"
        echo "Command failed. Attempt $n/$max:"
        echo "================================"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

rm -f cdn2.json
echo "============================================================================================================="
echo "OBTAINING CLOUDFRONT CONFIGURATION                                                                           "
echo "============================================================================================================="
retry /usr/local/bin/aws cloudfront get-distribution-config --id ${CDN_ID} > cdn.json
ETAG=$(cat cdn.json | jq -r .ETag)
CDN=$(cat cdn.json | jq -r 'del(.ETag)')
ORIGIN='
{
    "Id": "'$SHORT_DOMAIN_NAME-org'",
        "DomainName": "'$DOMAIN_NAME'",
        "OriginPath": "",
          "CustomHeaders": {
            "Quantity": 0
          },
          "CustomOriginConfig": {
            "HTTPPort": 80,
            "HTTPSPort": 443,
            "OriginProtocolPolicy": "http-only",
            "OriginSslProtocols": {
              "Quantity": 3,
              "Items": [
                "TLSv1",
                "TLSv1.1",
                "TLSv1.2"
              ]
            },
            "OriginReadTimeout": 30,
            "OriginKeepaliveTimeout": 5
          },
          "ConnectionAttempts": 3,
          "ConnectionTimeout": 10,
          "OriginShield": {
            "Enabled": false
          }
}'

BEHAVIOR='
        {
          "PathPattern": "/'$SHORT_DOMAIN_NAME'",
          "TargetOriginId": "'$SHORT_DOMAIN_NAME-org'",
          "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
          },
          "TrustedKeyGroups": {
            "Enabled": false,
            "Quantity": 0
          },
          "ViewerProtocolPolicy": "allow-all",
          "AllowedMethods": {
            "Quantity": 7,
            "Items": [
              "HEAD",
              "DELETE",
              "POST",
              "GET",
              "OPTIONS",
              "PUT",
              "PATCH"
            ],
            "CachedMethods": {
              "Quantity": 2,
              "Items": [
                "HEAD",
                "GET"
              ]
            }
          },
          "SmoothStreaming": false,
          "Compress": true,
          "LambdaFunctionAssociations": {
            "Quantity": 0
          },
          "FunctionAssociations": {
            "Quantity": 0
          },
          "FieldLevelEncryptionId": "",
          "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6"
        }'


echo "============================================================================================================="
echo "ADDING THE NEW ORIGIN TO THE  CONFIGURATION                                                                  "
echo "============================================================================================================="

CDN=$(echo $CDN | jq -r --argjson NewOrigin "$ORIGIN" '.DistributionConfig.Origins.Items[.DistributionConfig.Origins.Items | length] += $NewOrigin')
CDN=$(echo $CDN | jq '.DistributionConfig.Origins.Quantity +=1')

echo "============================================================================================================="
echo "ADDING THE NEW BEHAVIOR TO THE  CONFIGURATION                                                                "
echo "============================================================================================================="

CDN=$(echo $CDN | jq -r --argjson NewBehavior "$BEHAVIOR" '.DistributionConfig.CacheBehaviors.Items[.DistributionConfig.CacheBehaviors.Items | length] += $NewBehavior')
CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Quantity +=1')

echo "============================================================================================================="
echo "APPLYING THE  CONFIGURATION                                                                                  "
echo "============================================================================================================="
echo $CDN |jq -r .DistributionConfig > cdn2.json
result=$(retry /usr/local/bin/aws cloudfront update-distribution --id $CDN_ID --distribution-config file://cdn2.json --if-match ${ETAG})		

echo "============================================================================================================="
echo "WAITING TO SEE IF THE CONFIGURATION WAS APPLIED                                                              "
echo "============================================================================================================="
echo "$(echo $result | jq -r '.Distribution.Id + ": " + .Distribution.Status')"
/usr/local/bin/aws cloudfront wait distribution-deployed --id $CDN_ID && echo "Cloudfront Modification Completed";

rm -f cdn2.json