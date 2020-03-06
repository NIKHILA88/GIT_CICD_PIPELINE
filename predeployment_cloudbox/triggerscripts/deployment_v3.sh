
#!/bin/bash
#this script complets all the steps in application deployment
#please update indexes.txt (located in /tmp) with all the new app you want to deploy today

user= #<employeeid>
serverPass= #ldap pswd
username=admin #splunk admin user
secret= #splunk admin pswd
deployer=splunk-deployer11.prod.fedex.com #splunk deployer
clusterMaster=splunk-master11.prod.fedex.com #splunk clusterMaster
sh1=splunk-search11.prod.fedex.com #splunk any one of your SH

#clone umrf-conf-file-validation from git
cd /tmp
sudo -u splunk git clone git@gitlab.prod.fedex.com:APP3530768/umrf-conf-file-validation.git

for index in $(cat indexes.txt)
do
cd umrf-conf-file-validation
if [ ! -d $index ]; then
echo 'Index does not exist in gitlab, please double check the name of the index'
continue
fi

#create directory structure required for deployment
echo 'Create props and input directories and required subdirectories (default / local / metadata)'
sudo -u splunk mkdir -p /opt/splunk/current/etc/deployment-apps/$index\_props/default
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_props/local
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_props/metadata
sudo -u splunk mkdir -p /opt/splunk/current/etc/deployment-apps/$index\_inputs/default
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_inputs/local
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_inputs/metadata

#copy props.conf fom git clone to deployemt app
echo 'Placing props.conf from git in ~props/default'
sudo -u splunk cp /tmp/umrf-conf-file-validation/$index/test/props.conf /opt/splunk/current/etc/deployment-apps/$index\_props/default

#copy inputs.conf fom git clone to deployemt app
echo 'Placing inputs.conf from git in ~inputs/default'
sudo -u splunk cp /tmp/umrf-conf-file-validation/$index/test/inputs.conf /opt/splunk/current/etc/deployment-apps/$index\_inputs/default

#copy default search app files from gitclone to local search app
echo copy default search app files from gitclone to local search app
sudo -u splunk cp -Rf /tmp/umrf-conf-file-validation/search_app/test /opt/splunk/current/etc/deployment-apps/$index\_search


#create app.conf in props app
echo 'Creating app.conf in ~props/default'
printf '[install]\nstate = enabled\nstate_change_requires_restart = true\n\n
[package]\ncheck_for_updates = false\n\n
[ui]\nis_visible = false\nis_manageable = false' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_props/default/app.conf

#create default.meta in props app
echo 'Creating default.meta in ~props/metadata'
printf '[]\naccess = read:[*],write:[admin]\nexport=system' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_props/metadata/default.meta

#create app.conf in inputs app
echo 'Creating app.conf in ~inputs/default'
printf '[install]\nstate = enabled\nstate_change_requires_restart = true\n\n[package]\ncheck_for_updates = false\n\n[ui]\nis_visible = false\nis_manageable = false' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_inputs/default/app.conf

#create default.meta in inputs app
echo 'Creating default.meta in ~inputs/default'
printf '[]\naccess = read:[*],write:[admin]\nexport = system' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_inputs/metadata/default.meta

#show tree structure to validate if all directories are created or not
tree /opt/splunk/current/etc/deployment-apps/$index\_inputs
tree /opt/splunk/current/etc/deployment-apps/$index\_props
tree /opt/splunk/current/etc/deployment-apps/$index\_search

#adding Lable to app.conf
echo adding Lable to app.conf
esh1=`echo $index  | rev | cut -f2 -d"_" | rev`
echo $esh1
result=`echo $esh1 | tr '[:lower:]' '[:upper:]'`
echo $result
sed -i 's/Batman/'$result'/g' /opt/splunk/current/etc/deployment-apps/$index\_search/default/app.conf

#create 4 stanzas for serverclass.conf

printf '\n[serverClass:'$index':app:'$index'_inputs]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = enabled\n\n
[serverClass:All 1A Indexers via Master Node:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1A Search Heads via Deployer:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1A Search Heads via Deployer:app:'$index'_search]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n

[serverClass:'$index']
' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf
#whitelisting application servers
count=0
for host in $(cat /tmp/umrf-conf-file-validation/$index/test/hostlist.txt)
do
printf '\nwhitelist.'$count' = '$host'' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf
(( count++ ))
done

#create stanza for newly created index in indexe.conf

printf '\n['$index']\nhomePath = volume:default/'$index'/db\ncoldPath = volume:default/'$index'/colddb\nthawedPath = $SPLUNK_DB/'$index'/thaweddb\nfrozenTimePeriodInSecs = 1296000\n\n' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/fedex_1a_custom_indexes/local/indexes.conf

#reload serverclass
echo "Reloading the newly created serverclass (use admin login credentials)"
sudo -u splunk /opt/splunk/current/bin/splunk reload deploy-server $index -auth $username:$secret

done

#Push application bundle on clustermaster
sshpass -p "$serverPass" ssh -o StrictHostKeyChecking=no "$user$clusterMaster" "
echo Pushing application on Cluster Master
cd ../../opt/splunk/current/bin
echo Applying Cluster Bundle
sudo -u splunk ./splunk apply cluster-bundle -auth $username:$secret
exit "

#push application bundle on deployer
sshpass -p "$serverPass" ssh -o StrictHostKeyChecking=no "$user$deployer" "
echo Pushing application on Deployer
cd ../../opt/splunk/current/bin
sudo -u splunk ./splunk apply shcluster-bundle -target  https://$sh1:8089 -auth $username:$secret
exit "

#delete git clone from /tmp
echo "Remove Git repo from /tmp directory"
sudo -u splunk rm -r /tmp/umrf-conf-file-validation
