#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update system packages
sudo apt-get update -y

# Install Nginx
sudo apt-get install -y nginx

# Add Elastic repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

# Update package list after adding repository
sudo apt-get update -y

# Install Elasticsearch
sudo apt-get install -y elasticsearch

# Configure Elasticsearch
sudo sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
echo 'discovery.type: single-node' | sudo tee -a /etc/elasticsearch/elasticsearch.yml

# Configure JVM heap size
sudo sed -i 's/-Xms1g/-Xms512m/' /etc/elasticsearch/jvm.options
sudo sed -i 's/-Xmx1g/-Xmx512m/' /etc/elasticsearch/jvm.options

# Start and enable Elasticsearch
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

# Install Kibana
sudo apt-get install -y kibana

# Configure Kibana
sudo sed -i 's/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml
sudo sed -i 's/#server.host: "your-hostname"/server.host: "localhost"/' /etc/kibana/kibana.yml
sudo sed -i 's|#elasticsearch.hosts: \["http://localhost:9200"\]|elasticsearch.hosts: ["http://localhost:9200"]|' /etc/kibana/kibana.yml

# Start and enable Kibana
sudo systemctl start kibana
sudo systemctl enable kibana

# Open firewall for Kibana
sudo ufw allow 5601/tcp

# Install Logstash
sudo apt-get install -y logstash

# Start and enable Logstash
sudo systemctl start logstash
sudo systemctl enable logstash

# Install Filebeat
sudo apt-get install -y filebeat

# Configure Filebeat to send data to Elasticsearch
sudo sed -i 's/#output.elasticsearch:/output.elasticsearch:/' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  hosts: \["localhost:9200"\]|  hosts: ["localhost:9200"]|' /etc/filebeat/filebeat.yml

# Enable Filebeat system module
sudo filebeat modules enable system

# Load index template
sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'

# Start and enable Filebeat
sudo systemctl start filebeat
sudo systemctl enable filebeat

# Verify installation
curl -X GET "localhost:9200"
