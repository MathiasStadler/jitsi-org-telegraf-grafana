#!/bin/bash

# from here here https://explainshell.com/explain?cmd=set+-euxo%20pipefail
set -euxo pipefail
# set -euo pipefail # without x

DOCKER_COMPOSE="/usr/local/bin/docker-compose"
PARENT_PROJECT="../telegraf-influxdb-grafana-docker-composer"
WORK_FOLDER="work"

#  create work folder
mkdir -p ./$WORK_FOLDER

# determine ip of docker container that bas on image jitsi/jvb
IP_JITSI_JVB=$(docker ps | grep -i jitsi/jvb | awk '{print $1}' | xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "IP of Jitsi JVB Container ${IP_JITSI_JVB}"

# prepare file for /etc/telegraf/telegraf.d/jitsi.conf
TELEGRAF_JITSI_CONF="telegraf_jitsi.conf"

# content from here
# https://grafana.com/grafana/dashboards/11969
cat <<EOF | tee -a ${WORK_FOLDER}/${TELEGRAF_JITSI_CONF}
[[inputs.http]]
  name_override = "jitsi_stats"
  urls = [
    "http://${IP_JITSI_JVB}:8080/colibri/stats"
  ]

  data_format = "json"
EOF

## copy to work all ws we need to run

# copy grafana-provisioning to work folder
cp -a ./${PARENT_PROJECT}/grafana-provisioning ${WORK_FOLDER}

# copy influxdb.conf
cp -a ./${PARENT_PROJECT}/influxdb.conf ${WORK_FOLDER}

# copy jitsi-dashboard to work folder
cp ./jitsi-dashboard/* ./${WORK_FOLDER}/grafana-provisioning/dashboards

# copy .env to work folder
cp ./${PARENT_PROJECT}/.env ${WORK_FOLDER}/.env

# docker-composer yaml files
cp telegraf-jitsi.yml influxdb-grafana-jitsi.yml ./${WORK_FOLDER}

# change into work folder
pushd ${WORK_FOLDER}

# debug
echo " i'm work in folder ${PWD}"

# prepare keys for influxdb if not available ( self signed certificate )
SERVER_KEY_PEM="server-key.pem"
SERVER_CERT_PEM="server-cert.pem"

# check and create server key
if [ ! -f $SERVER_KEY_PEM ] && [ ! -s $SERVER_KEY_PEM ]; then
  echo "File ${SERVER_KEY_PEM} not found!"
  echo "create on ..."
  certtool --generate-privkey --outfile "${SERVER_KEY_PEM}" --sec-param Medium
  echo "..done"
else
  echo "File $SERVER_KEY_PEM found"
fi

# check and create cert key
if [ ! -f $SERVER_CERT_PEM ] && [ ! -s $SERVER_CERT_PEM ]; then
  echo "File ${SERVER_CERT_PEM} not found!"
  echo "create on ..."
  certtool --generate-self-signed --load-privkey "${SERVER_KEY_PEM}" --outfile "${SERVER_CERT_PEM}" --template ../${PARENT_PROJECT}/cert.cfg
  echo "..done"
else
  echo " FIle ${SERVER_CERT_PEM} found"
fi

# check is file not empty 
if [ ! -s $SERVER_CERT_PEM ]; then
  echo "ERROR: cert ${SERVER_CERT_PEM} file empty "
  echo " Delete file ${PWD}/${SERVER_CERT_PEM} and run script again and check output"
  exit 1
fi

# check docker container based on telegraf is running
if [[ "$(docker ps | grep -c telegraf)" = "0" ]]; then
  echo "start telegram container"
  # check docker-compose  file config
  PARENT_PROJECT=${PARENT_PROJECT} ${DOCKER_COMPOSE} -f ./telegraf-jitsi.yml config -q
  # start docker-compose
  PARENT_PROJECT=${PARENT_PROJECT} ${DOCKER_COMPOSE} -f ./telegraf-jitsi.yml up -d
else
  echo "Container base of image  telegraf still running!"
  echo "Please stop first manually and run the command again"
  echo "No telegraf container start"
fi

# check docker container based on telegraf is running
if [[ "$(docker ps | grep -c influxdb)" = "0" ]]; then
  echo "start telegram container"
  # check docker-compose  file config
  PARENT_PROJECT=${PARENT_PROJECT} ${DOCKER_COMPOSE} -f ./influxdb-grafana-jitsi.yml config -q
  #
  PARENT_PROJECT=${PARENT_PROJECT} ${DOCKER_COMPOSE} -f ./influxdb-grafana-jitsi.yml up -d
else
  echo "Container base of image  influxdb still running!!"
  echo "Please stop first manually and run the command again"
  echo "No influxdb container start"
fi

# leave work folder
popd
