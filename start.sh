#!/bin/bash

# from here here https://explainshell.com/explain?cmd=set+-euxo%20pipefail
set -euxo pipefail

DOCKER_COMPOSE="/usr/local/bin/docker-compose"
PARENT_PROJECT="telegraf-influxdb-grafana-docker-composer"
WORK_FOLDER="work"

#  create work folder
mkdir -p ./$WORK_FOLDER


# detemine ip of docker container that bas on image jitsi/jvb
IP_JITSI_JVB=$(docker ps |grep -i jitsi/jvb |awk  '{print $1}'|xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "IP of Jitsi JVB Container ${IP_JITSI_JVB}"

# prepare file for /etc/telegraf/telegraf.d/jitsi.conf
TELEGRAF_JITSI_CONF="telegraf_jitsi.conf"

# conten from here
# https://grafana.com/grafana/dashboards/11969
cat << EOF |tee -a ${WORK_FOLDER}/${TELEGRAF_JITSI_CONF}
[[inputs.http]]
  name_override = "jitsi_stats"
  urls = [
    # "http://localhost:8080/colibri/stats"
    "http://${IP_JITSI_JVB}:8080/colibri/stats"
  ]

  data_format = "json"
EOF

# copy grafana-provsisioning to work folder
cp -a ./${PARENT_PROJECT}/grafana-provisioning ${WORK_FOLDER}

# copy jitsi-dashboard to work folder
cp  ./jitsi-dashboard/* ./${WORK_FOLDER}/grafana-provisioning/dashboards

# cp env file to work folder
cp -a ./${PARENT_PROJECT}/.env ./${WORK_FOLDER}

# check docker container based on telegraf is running
if [[ "$(docker ps |grep -c telegraf)" ]] ; then
    echo "start telegram container"
    # check docker-compose  file config
    ${DOCKER_COMPOSE} -f telegraf-jitsi.yml config -q
    # 
    ${DOCKER_COMPOSE} -f telegraf-jitsi.yml up -d
else
   echo "Container base of image  telegraf still running!!"
   echo "Please stop first manually"
   echo "No telegraf container start" 
fi

# check docker container based on telegraf is running
if [[ "$(docker ps |grep -c influxdb)" ]] ; then
    echo "start telegram container"
    # check docker-compose  file config
    WORK_FOLDER=${WORK_FOLDER} ${DOCKER_COMPOSE} -f influxdb-grafana-jitsi.yml config -q
    # 
    WORK_FOLDER=${WORK_FOLDER} ${DOCKER_COMPOSE} -f influxdb-grafana-jitsi.yml up -d
else
   echo "Container base of image  influxdb still running!!"
   echo "Please stop first manually"
   echo "No influxdb container start" 
fi