#!/bin/bash

for index in `cat /opt/predeployment/indexes_list.txt`
do
curl -X POST -F token=89e4905cf43192fa9ab6f957703472 -F ref=master -F "variables[app]=$index" -F "variables[new]=no" https://gitlab.prod.fedex.com/api/v4/projects/17862/trigger/pipeline

done
[root@c0001195 predeployment]# cat cicd_onprem.sh
#!/bin/bash

for index in `cat /opt/predeployment/indexes_list.txt`
do
curl -X POST -F token=8f1e78393b1a253b46dce63c5112ec -F ref=master -F "variables[index]=$index" -F "variables[new]=no" https://gitlab.prod.fedex.com/api/v4/projects/14492/trigger/pipeline
done
