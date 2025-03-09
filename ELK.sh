#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update system packages
sudo apt update -y

# Add Elastic Repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update package list
sudo apt update -y

# Install Elasticsearch
sudo apt install -y elasticsearch

# Enable and start Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

# Install Kibana
sudo apt install -y kibana

# Enable and start Kibana
sudo systemctl enable kibana
sudo systemctl start kibana

# Open firewall for Kibana
sudo ufw allow 5601/tcp

# Install Logstash
sudo apt install -y logstash

# Enable and start Logstash
sudo systemctl enable logstash
sudo systemctl start logstash

# Configure Logstash
sudo tee /etc/logstash/conf.d/logstash.conf > /dev/null <<EOL
input {
  beats {
    port => 5044
  }
}

filter {
  # Optional filters can be added here
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
  }
  stdout {
    codec => rubydebug
  }
}
EOL

# Restart Logstash to apply configuration
sudo systemctl restart logstash

# Install Filebeat
sudo apt install -y filebeat

# Open firewall for Filebeat
sudo ufw allow 5044/tcp

# Configure Filebeat
sudo sed -i 's|#output.logstash:|output.logstash:|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  hosts: \["localhost:5044"\]|  hosts: ["localhost:5044"]|' /etc/filebeat/filebeat.yml

# Enable Filebeat system module
sudo filebeat modules enable system

# Load index template
sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'

# Start and enable Filebeat
sudo systemctl enable filebeat
sudo systemctl start filebeat

# Verify installation
curl -X GET "localhost:9200"
