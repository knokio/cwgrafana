#!/bin/bash

set -m

CONFIG_FILE="/etc/opt/influxdb/influxdb.conf"

echo "=> Starting InfluxDB ..."

exec service influxdb start
