# Remove firewalld
yum remove firewalld -y

# Install net-tools, ntp
yum install net-tools ntp -y
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
/var/ossec/bin/agent-auth -m 172.16.1.2 -A simple-ag
sed -i 's:MANAGER_IP:172.16.1.2:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent
