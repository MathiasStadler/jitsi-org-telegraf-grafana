#!/bin/bash

# from here here https://explainshell.com/explain?cmd=set+-euxo%20pipefail
set -euxo pipefail


# detemine ip of docker container that bas on image jitsi/jvb
IP_JITSI_JVB=$(docker ps |grep -i jitsi/jvb |awk  '{print $1}'|xargs docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "IP of Jitsi JVB Container ${IP_JITSI_JVB}"

# prepare file for /etc/telegraf/telegraf.d/jitsi.conf
TELEGRAF_JITSI_CONF="telegraf_jitsi.conf"

# conten from here
# https://grafana.com/grafana/dashboards/11969
cat << EOF |tee -a ${TELEGRAF_JITSI_CONF}
[[inputs.http]]
  name_override = "jitsi_stats"
  urls = [
    # "http://localhost:8080/colibri/stats"
    "http://${IP_JITSI_JVB}:8080/colibri/stats"
  ]

  data_format = "json"
EOF