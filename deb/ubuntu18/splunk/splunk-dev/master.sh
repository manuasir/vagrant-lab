# update packages
apt update

# Install net-tools
apt install net-tools ntp ntpdate -y

# Install git and zip
apt install git zip -y

#install wget
apt install wget -y

ntpdate -s time.nist.gov

# Wazuh dev repository
curl -s https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/apt-dev/ unstable main" | tee -a /etc/apt/sources.list.d/wazuh.list

# update packages
apt update

# Install Wazuh manager
apt install wazuh-manager -y

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
apt install nodejs -y 

# Install Wazuh API
apt install wazuh-api -y

# Wazuh cluster dependencies
apt install python-setuptools python-cryptography -y

# Configure Wazuh master node
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>172.16.1.4</node>:g' /var/ossec/etc/ossec.conf
sed -i -e '/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g' /var/ossec/etc/ossec.conf

# download splunkforwarder
wget -O splunkforwarder-7.2.0-8c86330ac18-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.0&product=universalforwarder&filename=splunkforwarder-7.2.0-8c86330ac18-linux-2.6-amd64.deb&wget=true'
# install splunkforwarder
dpkg --install splunkforwarder-7.2.0-8c86330ac18-linux-2.6-amd64.deb

# props.conf
curl -so /opt/splunkforwarder/etc/system/local/props.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/props.conf

# inputs.conf
curl -so /opt/splunkforwarder/etc/system/local/inputs.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/inputs.conf

# set hostname
sed -i "s:MANAGER_HOSTNAME:$(hostname):g" /opt/splunkforwarder/etc/system/local/inputs.conf

touch /opt/splunkforwarder/etc/system/local/user-seed.conf

# add admin user
cat > /opt/splunkforwarder/etc/system/local/user-seed.conf <<\EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

# accept license
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --auto-ports --no-prompt

# forward to index
/opt/splunkforwarder/bin/splunk add forward-server 172.16.1.6:9997 -auth admin:changeme

# restart service
/opt/splunkforwarder/bin/splunk restart

# Enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl enable wazuh-api

# Run Wazuh manager and Wazuh API
systemctl restart wazuh-manager
systemctl restart wazuh-api

echo "Listening authd..."

/var/ossec/bin/ossec-authd -i 