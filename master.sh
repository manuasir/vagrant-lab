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

# Install Wazuh manager
yum install wazuh-manager -y

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
yum install nodejs -y 

# Install Wazuh API
yum install wazuh-api -y

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y

# Configure Wazuh master node
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>192.168.1.193</node>:g' /var/ossec/etc/ossec.conf
sed -i 's:<disabled>yes</disabled>:<disabled>no</disabled>:g' /var/ossec/etc/ossec.conf

# Enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl enable wazuh-api

# Run Wazuh manager and Wazuh API
systemctl restart wazuh-manager
systemctl restart wazuh-api

: <<'COMMENT'
# Install Java 8
curl -Lo jre-8-linux-x64.rpm --header "Cookie: oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-linux-x64.rpm"
rpm -qlp jre-8-linux-x64.rpm > /dev/null 2>&1 && echo "Java package downloaded successfully" || echo "Java package did not download successfully"
yum -y install jre-8-linux-x64.rpm
rm -f jre-8-linux-x64.rpm

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

# Install Logstash
yum install elasticsearch-6.3.2 logstash-6.3.2 filebeat-6.3.2 kibana-6.3.2 -y

# Enable Elastic services
systemctl daemon-reload
systemctl enable elasticsearch
systemctl enable logstash
systemctl enable filebeat
systemctl enable kibana

# Run Elasticsearch
systemctl restart elasticsearch

# Wait for Elasticsearch
sleep 20

# Insert the template
curl https://raw.githubusercontent.com/wazuh/wazuh/3.4/extensions/elasticsearch/wazuh-elastic6-template-alerts.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-

# Logstash remote configuration
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.4/extensions/logstash/01-wazuh-remote.conf

# Filebeat configuration
curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/3.4/extensions/filebeat/filebeat.yml
sed -i 's:ELASTIC_SERVER_IP:127.0.0.1:g' /etc/filebeat/filebeat.yml

# Run Logstash
systemctl restart logstash

# Run Filebeat
systemctl restart filebeat

# Run Kibana
systemctl restart kibana
COMMENT

echo "Listening authd..."

/var/ossec/bin/ossec-authd -ddf -i &