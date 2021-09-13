#!/bin/bash

echo 1) List agents

docker exec -it mftlab_agent10_1 fteListAgents

echo 2) agent10:/mountpath/agent20/flow1/input/new/

docker exec -it mftlab_agent10_1 ls -lh /mountpath/agent20/flow1/input/new/

echo 3) Check if a simple transfer is working

docker exec -it mftlab_agent10_1 fteCreateTransfer -p MQMFT -t binary -sa AGENT10 -sm MQMFT -da AGENT20 -dm MQMFT -de overwrite -dd "/mountpath/agent10/flow1/output/new/" "/mountpath/agent20/flow1/input/new/*"
docker exec -it mftlab_agent10_1 mqfts

echo 4) agent20:/mountpath/agent10/flow1/output/new/

docker exec -it mftlab_agent20_1 ls -lh /mountpath/agent10/flow1/output/new/

echo 5) Create a Monitor

docker exec -it mftlab_agent10_1 fteCreateTransfer -gt /mountpath/task.xml -sa AGENT10 -sm MQMFT -da AGENT20 -dm MQMFT -sd delete -de overwrite -dd "/mountpath/agent10/flow2/output/new/" "\${FilePath}"
docker exec -it mftlab_agent10_1 fteCreateMonitor -p MQMFT -ma AGENT10 -mn AGENT10_AGENT20_FLOW2 -md "/mountpath/agent20/flow2/input/new/" -pi 15 -pu SECONDS -pt wildcard -tr "noSizeChange=2,*.csv" -f -mt /mountpath/task.xml

echo 6) List a Monitor

docker exec -it mftlab_agent10_1 fteListMonitors -v -ma AGENT10 -mn AGENT10_AGENT20_FLOW2

echo 7) Check transfers

docker exec -it mftlab_agent10_1 mqfts

echo 8) Create a data/agent10/agent20/flow2/input/new/newsalary.csv file

echo ${RANDOM} > data/agent10/agent20/flow2/input/new/newsalary.csv

echo 9) Wait and see at destination

sleep 20 ; docker exec -it mftlab_agent20_1 ls -lh /mountpath/agent10/flow2/output/new/newsalary.csv

echo 10) Create a data/agent10/agent20/flow2/input/new/oldperks.xls file

echo ${RANDOM} > data/agent10/agent20/flow2/input/new/oldperks.xls

echo 11) Wait and see at destination

sleep 20 ; docker exec -it mftlab_agent20_1 ls -lh /mountpath/agent10/flow2/output/new/oldperks.xls

docker exec -it mftlab_agent10_1 mqfts
