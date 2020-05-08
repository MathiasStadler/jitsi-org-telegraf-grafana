# jitsi-org-telegraf-grafana

## TL;DR

git commit
git submodule update

## housekeeping

- start code server

```bash
docker run -it -d -p 8080:8080 -v "/home/trapapa/playground/jitsi-org-telegraf-grafana:/home/coder/project" -u "$(id -u):$(id -g)" codercom/code-server:latest --cert
```

- settings for github
git config --global user.name "Mathias Stadler"

git config --global user.EMAIL "email@mathias-stadler.de"

https://help.github.com/en/github/using-git/caching-your-github-password-in-git

git config --global credential.helper 'cache --timeout=3600'

- install vscode extension
Press Ctrl+P or Cmd+P and type:
ext install Gruntfuggly.todo-tree
ext install markdownlint
ext install code-spell-checker

- install shellcheck extension

```bash
# inside the terminal
sudo apt-get update
sudo apt-get install -y shellcheck
```

- in command line ( Ctrl+P or Cmd+P )
ext install shellcheck
ext install shell-format

## source

```txt
# telegraf http setting sample
https://community.jitsi.org/t/monitoring-with-grafana/27399/3
#
https://grafana.com/grafana/dashboards/11969
#
https://github.com/jitsi/jitsi-videobridge/blob/master/doc/rest.md
#
https://community.jitsi.org/t/how-to-enable-colibri-stats-in-docker-installations/20915/6
```

## jitsi docker settings

```bash
I enabled JVB_ENABLE_APIS=rest,colibri in .env and restart docker-compose
then its working
curl 172.18.0.8:8080/colibri/stats
172.18.0.8 is jvb docker container ip
```

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name_or_id

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'  dockerjitsimeet_jvb_1

curl 192.168.128.5:8080/colibri/stats

docker network inspect bridge

docker network inspect dockerjitsimeet_meet.jitsi

## reread conf without shutdown

pkill -1 telegraf

/etc/telegraf/telegraf.d/jitsi.conf

[[inputs.http]]
  name_override = "jitsi_stats"
  urls = [
    "http://localhost:8080/colibri/stats"
  ]

  data_format = "json"

## docker priority of same environment variable

- from here https://docs.docker.com/compose/environment-variables/

When you set the same environment variable in multiple files, here’s the priority used by Compose to choose which value to use:

Compose file
Shell environment variables
Environment file
Dockerfile
Variable is not defined



Build context is always the location of docker-compose.yaml
