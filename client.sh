# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools -y
yum install curl -y 
yum install wget -y 
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

# download splunkforwarder
wget -O splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.3&product=universalforwarder&filename=splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm&wget=true'

# install splunkforwarder
yum install -y splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm

# set hostname
sed -i "s:MANAGER_HOSTNAME:$(hostname):g" /opt/splunkforwarder/etc/system/local/inputs.conf

# props.conf
curl -so /opt/splunkforwarder/etc/system/local/props.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/props.conf

# inputs.conf
curl -so /opt/splunkforwarder/etc/system/local/inputs.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/inputs.conf

# accept license
## /opt/splunkforwarder/bin/splunk start --accept-license

# forward to index
# /opt/splunkforwarder/bin/splunk add forward-server 192.168.1.195:9997

# restart service
# /opt/splunkforwarder/bin/splunk restart

systemctl daemon-reload

systemctl enable wazuh-manager


# Wazuh cluster configuration
sed -i 's:<node_name>node01</node_name>:<node_name>node02</node_name>:g' /var/ossec/etc/ossec.conf
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>192.168.1.193</node>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node_type>master</node_type>:<node_type>client</node_type>:g' /var/ossec/etc/ossec.conf
sed -i 's:<disabled>yes</disabled>:<disabled>no</disabled>:g' /var/ossec/etc/ossec.conf

# Run Wazuh manager
systemctl restart wazuh-manager

