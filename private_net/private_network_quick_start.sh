#!/bin/bash

WORK_SPACE=$PWD
CONF_PATH="$WORK_SPACE/conf"

echo 'download config files from repository'
if [ ! -e CONF_PATH ]; then
  mkdir -p $CONF_PATH
fi

# Download the remote config file
curl -o $CONF_PATH/private_net_config_others.conf https://raw.githubusercontent.com/DongDongSunny/tron-deployment/master/private_net/private_net_config_others.conf
curl -o $CONF_PATH/private_net_config_witness.conf https://raw.githubusercontent.com/DongDongSunny/tron-deployment/master/private_net/private_net_config_witness.conf

# Run Docker Compose
docker-compose up -d