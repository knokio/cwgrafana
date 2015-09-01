FROM phusion/baseimage:0.9.16

ENV GRAFANA_VERSION 2.1.3
ENV INFLUXDB_VERSION 0.9.3

# ---------------- #
#   Installation   #
# ---------------- #

# Install all prerequisites
RUN 	apt-get update
RUN 	apt-get -y install wget curl adduser libfontconfig

# Install Grafana to /src/grafana
RUN		wget https://grafanarel.s3.amazonaws.com/builds/grafana_${GRAFANA_VERSION}_amd64.deb && \
			dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && rm grafana_${GRAFANA_VERSION}_amd64.deb

# Install InfluxDB
RUN		wget http://s3.amazonaws.com/influxdb/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
			dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# -------------- #
#   CloudWatch   #
# -------------- #

# Add a script run automatically at startup that creates /docker.env
# so that the Cron job can access the AWS credentials env variables
ADD cloudwatch/env2file /etc/my_init.d/env2file

RUN apt-get -y install python-pip 

RUN pip install --global-option="--without-libyaml" PyYAML
# ^- libyaml seems to be unavailable here; cloudwatch dependency
RUN pip install cloudwatch-to-graphite==0.5.0

ADD cloudwatch/leadbutt-cloudwatch.conf /etc/leadbutt-cloudwatch.conf
ADD cloudwatch/leadbutt-cloudwatch-cron.conf /etc/cron.d/leadbutt-cloudwatch

RUN apt-get -y install netcat

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure InfluxDB
ADD		influxdb/config.toml /etc/opt/influxdb/influxdb.conf

RUN 	mkdir -p /var/easydeploy/share /var/easydeploy/share/influxdb
RUN 	chown influxdb:influxdb -R /var/easydeploy/share/influxdb

# Configure Grafana
ADD		./grafana/config.js /src/grafana/config.js

# These database has to be created. These variables are used by set_influxdb.sh and set_grafana.sh
ENV		PRE_CREATE_DB data
ENV		INFLUXDB_DATA_USER data
ENV		INFLUXDB_DATA_PW data
ENV		ROOT_PW root

RUN     service grafana-server start
RUN     service influxdb start

ADD		./set_grafana.sh /set_grafana.sh
ADD		./set_influxdb.sh /set_influxdb.sh

ADD		./configure.sh /configure.sh
RUN 	/configure.sh

RUN     service grafana-server stop
RUN     service influxdb stop

# ----------------- #
#   Startup         #
# ----------------- #

ADD		influxdb/run.sh /etc/service/influxdb/run
ADD		grafana/run.sh /etc/service/grafana/run

RUN 	chmod +x /etc/service/influxdb/run /etc/service/grafana/run

# ----------------- #
#   Crontab         #
# ----------------- #

# TODO(improvement) use crontab fragments in /etc/cron.d/ instead of using root's crontab
# See for other tips: http://stackoverflow.com/questions/26822067/running-cron-python-jobs-within-docker
RUN crontab /etc/cron.d/leadbutt-cloudwatch

# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE	80

# InfluxDB Admin server
EXPOSE	8083

# InfluxDB HTTP API
EXPOSE	8086

# InfluxDB HTTPS API
EXPOSE	8084


# -------- #
#   Run!   #
# -------- #

CMD ["/sbin/my_init"]
