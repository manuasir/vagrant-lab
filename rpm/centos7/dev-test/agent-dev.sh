# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools -y

# Wazuh repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# Install Wazuh agent
yum install wazuh-agent -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 172.16.1.4 -A agent$(( ( RANDOM % 1000 )  + 1 ))
sed -i 's:MANAGER_IP:172.16.1.4:g' /var/ossec/etc/ossec.conf

# delete last line
sed -i '$ d' /var/ossec/etc/ossec.conf

# delete previous labels
sed -i '/<labels>/,/<\/labels>/d' /var/ossec/etc/ossec.conf

# labels
cat >> /var/ossec/etc/ossec.conf<<\EOF
<labels>
    <label key="aws.instance-id">i-052a1838c</label>
    <label key="aws.sec-group">sg-1103</label>
    <label key="network.ip">172.17.0.0</label>
    <label key="network.mac">02:42:ac:11:00:02</label>
    <label key="installation" hidden="yes">January 1st, 2017</label>
</labels>
EOF

# last line
cat >> /var/ossec/etc/ossec.conf<<\EOF
</ossec_config>
EOF


# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent
