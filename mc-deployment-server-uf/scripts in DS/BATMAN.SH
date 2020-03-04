#!/bin/bash
set -x
#this script complets all the steps in application deployment
#please update indexes.txt (located in /tmp) with all the new app you want to deploy today


user=f3763442 #<employeeid>
serverPass=Tan31027 #ldap pswd
username=admin #splunk admin user
secret=HickoryTime3456 #splunk admin pswd
deployer=splunk-deployer11.prod.fedex.com #splunk deployer
clusterMaster=splunk-master11.prod.fedex.com #splunk clusterMaster
sh1=splunk-search11.prod.fedex.com #splunk any one of your SH

echo clone umrf-conf-file-validation from git
cd /tmp
sudo -u splunk git clone git@gitlab.prod.fedex.com:APP3530768/umrf-conf-file-validation.git

for index in $(cat indexes.txt)
do

echo copy default search app files from gitclone to local search app
sudo -u splunk cp -Rf /tmp/umrf-conf-file-validation/search_app/test/* /opt/splunk/current/etc/deployment-apps/$index\_search/*


echo adding Lable to app.conf
esh1=`echo $index  | rev | cut -f2 -d"_" | rev`
echo $esh1
result=`echo $esh1 | tr '[:lower:]' '[:upper:]'`
echo $result

sed -i 's/Batman/'$result'/g' /opt/splunk/current/etc/deployment-apps/$index\_search/default/app.conf
#printf '\n[serverClass:All 1A Search Heads via Deployer:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
done
