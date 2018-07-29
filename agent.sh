# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools -y

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
yum install wazuh-agent -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 192.168.1.193 -A agent$(( ( RANDOM % 1000 )  + 1 ))
sed -i 's:MANAGER_IP:192.168.1.193:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent
