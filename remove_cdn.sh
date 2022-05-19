#!/bin/bash
#====================================================================================================================
#Script that remove a origin and behavior to a cloudfront distribution , only for Load Balancers for the moment
#====================================================================================================================
: ${1?"How to use: $0 CLOUDFRONT_ID DOMAIN_PATH"}
: ${2?"How to use: $0 CLOUDFRONT_ID DOMAIN_PATH"}

CDN_ID=$1            #E3554BHOW3RXY2
SHORT_DOMAIN_NAME=$2 #crm-uat-prod
AWS_PATH=/usr/bin/aws
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
retry $AWS_PATH cloudfront get-distribution-config --id ${CDN_ID} > cdn.json
ETAG=$(cat cdn.json | jq -r .ETag)
CDN=$(cat cdn.json | jq -r 'del(.ETag)')
SHORT_DOMAIN_NAME_ORG=$SHORT_DOMAIN_NAME-org

echo "============================================================================================================="
echo "REMOVING THE ORIGIN FROM THE CONFIGURATION                                                                  "
echo "============================================================================================================="

CDN=$(echo $CDN | jq --arg RemoveOrigin "$SHORT_DOMAIN_NAME_ORG" 'del(.DistributionConfig.Origins.Items[] | select(.Id == $RemoveOrigin))')
CDN=$(echo $CDN | jq '.DistributionConfig.Origins.Quantity -=1')

echo "============================================================================================================="
echo "REMOVING THE NEW BEHAVIOR FROM THE CONFIGURATION                                                                "
echo "============================================================================================================="

CDN=$(echo $CDN | jq --arg RemoveOrigin "$SHORT_DOMAIN_NAME_ORG" 'del(.DistributionConfig.CacheBehaviors.Items[] | select(.TargetOriginId == $RemoveOrigin))')
CDN=$(echo $CDN | jq '.DistributionConfig.CacheBehaviors.Quantity -=1')

echo "============================================================================================================="
echo "APPLYING THE  CONFIGURATION                                                                                  "
echo "============================================================================================================="
echo $CDN |jq -r .DistributionConfig > cdn2.json
result=$(retry $AWS_PATH cloudfront update-distribution --id $CDN_ID --distribution-config file://cdn2.json --if-match ${ETAG})		

echo "============================================================================================================="
echo "WAITING TO SEE IF THE CONFIGURATION WAS APPLIED                                                              "
echo "============================================================================================================="
echo "$(echo $result | jq -r '.Distribution.Id + ": " + .Distribution.Status')"
retry $AWS_PATH cloudfront wait distribution-deployed --id $CDN_ID && echo "Cloudfront Modification Completed";

rm -f cdn2.json