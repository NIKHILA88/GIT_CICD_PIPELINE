printf 'Predeployment Tasks:\n1. Create inputs and props directories\n2. Create subdirectories\n3. Populate generic files\n'
echo "Type the name of your application index (i.e. fedex_app_eai_1234 - this should be identical to the name of the folder in Git), followed by [ENTER]:"
read index

cd /tmp
sudo -u splunk git clone git@gitlab.prod.fedex.com:APP3530768/umrf-conf-file-validation.git
cd umrf-conf-file-validation
if [ ! -d $index ]; then
    echo 'Index does not exist in gitlab, please double check the name of the index'
    exit 1
fi

echo 'Create props and input directories and required subdirectories (default / local / metadata)'
sudo -u splunk mkdir -p /opt/splunk/current/etc/deployment-apps/$index\_props/default
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_props/local
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_props/metadata
sudo -u splunk mkdir -p /opt/splunk/current/etc/deployment-apps/$index\_inputs/default
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_inputs/local
sudo -u splunk mkdir /opt/splunk/current/etc/deployment-apps/$index\_inputs/metadata

echo 'Placing props.conf from git in ~props/default'
sudo -u splunk cp /tmp/umrf-conf-file-validation/$index/test/props.conf /opt/splunk/current/etc/deployment-apps/$index\_props/default

echo 'Placing inputs.conf from git in ~inputs/default'
sudo -u splunk cp /tmp/umrf-conf-file-validation/$index/test/inputs.conf /opt/splunk/current/etc/deployment-apps/$index\_inputs/default

echo 'Creating app.conf in ~props/default'
printf '[install]\nstate = enabled\nstate_change_requires_restart = true\n\n
[package]\ncheck_for_updates = false\n\n
[ui]\nis_visible = false\nis_manageable = false' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_props/default/app.conf
echo 'Creating default.meta in ~props/metadata'
printf '[]\naccess = read:[*],write:[admin]\nexport=system' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_props/metadata/default.meta
echo 'Creating app.conf in ~inputs/default'
printf '[install]\nstate = enabled\nstate_change_requires_restart = true\n\n[package]\ncheck_for_updates = false\n\n[ui]\nis_visible = false\nis_manageable = false' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_inputs/default/app.conf
echo 'Creating default.meta in ~inputs/default'
printf '[]\naccess = read:[*],write:[admin]\nexport = system' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/$index\_inputs/metadata/default.meta

echo "Updating serverclass.conf default settings"
printf '\n[serverClass:'$index':'$index'_inputs]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = enabled\n\n
[serverClass:All 1A Indexers via Master Node:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:All 1A Search Heads via Deployer:app:'$index'_props]\nrestartSplunkWeb = 0\nrestartSplunkd = 0\nstateOnClient = noop\n\n
[serverClass:'$index']' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf

echo "Updating serverclass.conf with hosts"
count=0
for host in $(cat /tmp/umrf-conf-file-validation/$index/test/hostlist.txt)
do
    printf 'whitelist.'$count' = '$host'\n'
    printf 'whitelist.'$count' = '$host'\n' | sudo -u splunk tee -a /opt/splunk/current/etc/system/local/serverclass.conf
    (( count++ ))
done

echo "Updating indexes.conf with $index"
printf '\n['$index']\nhomePath = volume:default/'$index'/db\ncoldPath = volume:default/'$index'/colddb\nthawedPath = $SPLUNK_DB/'$index'/thaweddb\nfrozenTimePeriodInSecs = 1296000' | sudo -u splunk tee -a /opt/splunk/current/etc/deployment-apps/fedex_1a_custom_indexes/local/indexes.conf

echo "Remove Git repo from /tmp directory"
sudo -u splunk rm -rf /tmp/umrf-conf-file-validation

echo "Proceed on with manual steps of reloading Deployment Server and pushing on Cluster Master and Deployer"[
