#!/bin/bash

set -m

echo "=> Starting Grafana ..."

exec service grafana-server start
