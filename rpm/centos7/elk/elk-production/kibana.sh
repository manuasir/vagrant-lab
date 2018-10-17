# Remove firewalld
yum remove firewalld -y

# Install net-tools, git, zip, ntp
yum install net-tools git zip ntp -y
ntpdate -s time.nist.gov

# Wazuh repository
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1
EOF

# Install Wazuh agent
yum install wazuh-agent-3.6.1 -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 172.16.1.2 -A kibana-ag
sed -i 's:MANAGER_IP:172.16.1.2:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# Elastic GPG KEY
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

# Elastic repository
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Kibana
yum install kibana-6.4.1 -y

# Enable Elastic services
systemctl daemon-reload
systemctl enable kibana

# Install Wazuh app from URL
export NODE_OPTIONS="--max-old-space-size=3072"
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-3.6.1_6.4.1.zip

# Kibana configuration
sed -i 's:\#server.host\: "localhost":server\.host\: "0.0.0.0":g' /etc/kibana/kibana.yml
sed -i 's:#elasticsearch.url:elasticsearch.url:g' /etc/kibana/kibana.yml
sed -i 's#http://localhost:9200#http://172.16.1.4:9200#g' /etc/kibana/kibana.yml

# Run Kibana
systemctl restart kibana
