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

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y

: <<'COMMENT'
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

# Install Filebeat
yum install filebeat-6.3.2 -y

# Enable services
systemctl daemon-reload
systemctl enable filebeat
systemctl enable wazuh-manager

# Filebeat configuration
curl -so /etc/filebeat/filebeat.yml https://raw.githubusercontent.com/wazuh/wazuh/3.4/extensions/filebeat/filebeat.yml
sed -i 's:ELASTIC_SERVER_IP:192.168.1.193:g' /etc/filebeat/filebeat.yml
COMMENT

# Wazuh cluster configuration
sed -i 's:<node_name>node01</node_name>:<node_name>node02</node_name>:g' /var/ossec/etc/ossec.conf
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>192.168.1.193</node>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node_type>master</node_type>:<node_type>client</node_type>:g' /var/ossec/etc/ossec.conf
sed -i 's:<disabled>yes</disabled>:<disabled>no</disabled>:g' /var/ossec/etc/ossec.conf

# Run Wazuh manager
systemctl restart wazuh-manager

# Run Filebeat
# systemctl restart filebeat