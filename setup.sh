#!/bin/sh

DATA_DIR=/home/ubuntu/stuff
CODE_DIR=`pwd`
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt-get -y install ca-certificates curl gnupg lsb-release docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose apt-transport-https software-properties-common wget unzip grafana 

mkdir $DATA_DIR/monitoring
mkdir $DATA_DIR/nodes
mkdir $DATA_DIR/nodes/ethereum
mkdir $DATA_DIR/nodes/dogecoin
cp ./nodes/.env $DATA_DIR/nodes/
cp ./nodes/docker-compose.yaml $DATA_DIR/nodes/


cd $DATA_DIR/monitoring
wget https://github.com/prometheus/prometheus/releases/download/v2.38.0/prometheus-2.38.0.linux-amd64.tar.gz
tar -xf ./prometheus-2.38.0.linux-amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0-rc.0/node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
tar -xf ./node_exporter-1.4.0-rc.0.linux-amd64.tar.gz
sudo useradd --system --no-create-home --shell /usr/sbin/nologin prometheus
sudo useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
sudo mv prometheus-2.38.0.linux-amd64 /opt/prometheus
sudo mv node_exporter-1.4.0-rc.0.linux-amd64 /opt/node_exporter
sudo chmod -R 0755 /opt/prometheus
sudo chmod -R 0755 /opt/node_exporter
sudo mkdir /opt/prometheus/data
wget https://github.com/grafana/loki/releases/download/v2.6.1/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
wget https://github.com/grafana/loki/releases/download/v2.6.1/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mkdir /opt/loki
sudo mkdir /opt/promtail
sudo useradd --system --no-create-home --shell /usr/sbin/nologin loki
sudo chmod -R 0755 /opt/loki
sudo chmod -R 0755 /opt/promtail
sudo mv loki-linux-amd64 /opt/loki/loki
sudo mv promtail-linux-amd64 /opt/promtail/promtail

cd $CODE_DIR
sudo cp ./service/loki.service /etc/systemd/system/
sudo cp ./service/node_exporter.service /etc/systemd/system/
sudo cp ./service/prometheus.service /etc/systemd/system/
sudo cp ./service/promtail.service /etc/systemd/system/
sudo cp ./config/loki.yml /opt/loki/
sudo cp ./config/prometheus.yml /opt/prometheus/
sudo cp ./config/promtail.yml /opt/promtail/

sudo chown -R prometheus:prometheus /opt/prometheus/data

sudo systemctl daemon-reload
sudo systemctl enable prometheus.service
sudo systemctl start prometheus.service
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter.service
sudo systemctl start loki.service
sudo systemctl enable loki.service
sudo systemctl start promtail.service
sudo systemctl enable promtail.service
sudo systemctl start grafana-server.service
cd $DATA_DIR/nodes
sudo docker-compose --env-file ./.env up -d

cd $CODE_DIR
sudo cp -r ./config/grafana/provisioning/* /etc/grafana/provisioning/
