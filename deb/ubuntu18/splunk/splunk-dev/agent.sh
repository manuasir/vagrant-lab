#update packages
apt update

# Install net-tools
apt install net-tools -y

# Wazuh dev repository
curl -s https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/apt-dev/ unstable main" | tee -a /etc/apt/sources.list.d/wazuh.list

#update packages
apt update

# Install Wazuh agent
apt install wazuh-agent -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 172.16.1.4 -A agent$(( ( RANDOM % 1000 )  + 1 ))
sed -i 's:MANAGER_IP:172.16.1.4:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent
