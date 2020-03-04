#!/bin/bash
#this script is a standalone for On-prem re-Deployment
#please update deployment_indexes.txt (located in gitlab.prod.fedex.com:APP3530768/umrf-onboarding.git) with all the new app you want to deploy today
#For pushing bundles from CM and Deployer, secondary scripts are being called for the .gitlab-ci.yml file.
set -x

cd /tmp/
git clone git@gitlab.prod.fedex.com:APP3530768/umrf-conf-file-validation.git
git clone git@gitlab.prod.fedex.com:APP3530768/test-deployment-server.git
cd umrf-conf-file-validation

for index in $(cat deployment_indexes.txt)
do

cp -R /tmp/test-deployment-server/deployment-apps/$index\_* /opt/splunk/current/etc/deployment-apps/

done


echo delete git clone from /tmp
rm -rf /tmp/umrf-conf-file-validation
echo delete Deployment-Indexes
rm /tmp/deployment_indexes.txt

