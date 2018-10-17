# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools -y

# Wazuh repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# Install Wazuh agent
yum install wazuh-agent-3.7.0 -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 172.16.1.5 -A agent$(( ( RANDOM % 1000 )  + 1 ))
sed -i 's:MANAGER_IP:172.16.1.5:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent
