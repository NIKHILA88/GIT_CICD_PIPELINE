#!/bin/bash
#this script is a standalone for On-prem Deployment
#please update deployment_indexes.txt (located in gitlab.prod.fedex.com:APP3530768/umrf-onboarding.git) with all the new app you want to deploy today
#For pushing bundles from CM and Deployer, secondary scripts are being called for the .gitlab-ci.yml file.
set -x

echo $1

git clone git@gitlab.prod.fedex.com:APP3530768/umrf-conf-file-validation.git /opt/splunk/gitRepo/umrf-conf-file-validation
cd /opt/splunk/gitRepo/umrf-conf-file-validation


echo "create 4 stanzas for serverclass.conf"

printf '\n[serverClass:'$1':app:'$1'_inputs]\nrestartSplunkWeb = 0\nrestartSplunkd = 1\nstateOnClient = enabled\n\n
[serverClass:All 1B Indexers via Master Node:app:'$1'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1B Search Heads via Deployer:app:'$1'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1B Search Heads via Deployer:app:'$1'_search]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n

[serverClass:'$1']
' | tee -a /opt/splunk/current/etc/system/local/serverclass.conf


echo "whitelisting application servers"
count=0
for host in $(cat /opt/splunk/gitRepo/umrf-conf-file-validation/$1/docs/testhosts.txt)
do
printf 'whitelist.'$count' = '$host'\n' | tee -a /opt/splunk/current/etc/system/local/serverclass.conf
(( count++ ))
done

echo "create stanza for newly created index in index.conf"

printf '\n['$1']\nhomePath = volume:default/'$1'/db\ncoldPath = volume:default/'$1'/colddb\nthawedPath = $SPLUNK_DB/'$1'/thaweddb\nfrozenTimePeriodInSecs = 1296000\n\n' | tee -a /opt/splunk/current/etc/deployment-apps/fedex_1b_custom_indexes/local/indexes.conf



echo delete git clone from /tmp
rm -rf /opt/splunk/gitRepo/umrf-conf-file-validation
