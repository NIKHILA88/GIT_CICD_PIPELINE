#!/bin/bash
#this script is a support script for Gitlab CI/CD pipeline
#please update deployment_indexes.txt (located in gitlab.prod.fedex.com:APP3530768/umrf-onboarding.git) with all the new app you want to deploy today
#For pushing bundles from CM and Deployer, secondary scripts are being called for the .gitlab-ci.yml file.
set -x

username="f3763442" #<employee ID>
user="admin" #<splunk Login>
pass=`cat /opt/home/splunk/.adminpass64 |base64 --decode` #Splunk Admin pswd
secret=`cat /opt/home/splunk/.adminp64 |base64 --decode` #Splunk Admin pswd

me=`whoami`
if [ $me = "splunk" ]
  then
    echo "You are Logged in as Splunk!!!!"
   exit 1
fi

echo cloning umrf-onboarding from git
cd /tmp/
sudo -u splunk git clone git@gitlab.prod.fedex.com:APP3530768/umrf-onboarding.git

echo copy deployment_indexes.txt to tmp
cd umrf-onboarding/
cp deployment_indexes.txt /tmp/
cd /tmp/

for index in $(cat deployment_indexes.txt)
do

echo show tree structure to validate if all directories are created or not
tree /opt/splunk/current/etc/deployment-apps/$index\_inputs
tree /opt/splunk/current/etc/deployment-apps/$index\_props
tree /opt/splunk/current/etc/deployment-apps/$index\_search

echo create 4 stanzas for serverclass.conf

printf '\n[serverClass:'$index':app:'$index'_inputs]\nrestartSplunkWeb = 0\nrestartSplunkd = 1\nstateOnClient = enabled\n\n
[serverClass:All 1A Indexers via Master Node:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1A Search Heads via Deployer:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1A Search Heads via Deployer:app:'$index'_search]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n

[serverClass:'$index']
' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf
echo whitelisting application servers
count=0
for host in $(cat /tmp/umrf-onboarding/$index/test/hostlist.txt)
do
printf 'whitelist.'$count' = '$host'\n' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf
(( count++ ))
done

echo create stanza for newly created index in index.conf

printf '\n['$index']\nhomePath = volume:default/'$index'/db\ncoldPath = volume:default/'$index'/colddb\nthawedPath = $SPLUNK_DB/'$index'/thaweddb\nfrozenTimePeriodInSecs = 1296000\n\n' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/fedex_1a_custom_indexes/local/indexes.conf

echo reload serverclass
sudo -u splunk /opt/splunk/current/bin/splunk reload deploy-server $index -auth $user:$pass

done

sudo -u splunk /opt/splunk/current/bin/splunk reload deploy-server -class "All 1A Indexers via Master Node" -auth $user:$pass
sudo -u splunk /opt/splunk/current/bin/splunk reload deploy-server -timeout 200 -class "All 1A Search Heads via Deployer" -auth $user:$pass

echo delete git clone from /tmp
sudo -u splunk rm -r /tmp/umrf-onboarding
echo delete deployment_indexes from /tmp
sudo -u splunk rm /tmp/deployment-indexes.txt
