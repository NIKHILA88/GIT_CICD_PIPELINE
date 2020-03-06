#!/bin/bash

for index in `cat /opt/predeployment/indexes_list.txt`
do
curl -X POST -F token=89e4905cf43192fa9ab6f957703472 -F ref=master -F "variables[app]=$index" -F "variables[new]=no" https://gitlab.prod.fedex.com/api/v4/projects/17862/trigger/pipeline

done
