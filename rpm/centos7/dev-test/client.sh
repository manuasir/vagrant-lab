# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools ntp -y
yum install curl -y 
yum install wget -y
ntpdate -s time.nist.gov

# Wazuh repository
echo -e '[wazuh_pre_release]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo

# Install Wazuh manager
yum install wazuh-manager -y

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y

systemctl daemon-reload

systemctl enable wazuh-manager

# Wazuh cluster configuration
sed -i 's:<node_name>node01</node_name>:<node_name>client</node_name>:g' /var/ossec/etc/ossec.conf
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>172.16.1.4</node>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node_type>master</node_type>:<node_type>client</node_type>:g' /var/ossec/etc/ossec.conf
sed -i -e '/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g' /var/ossec/etc/ossec.conf

# Run Wazuh manager
systemctl restart wazuh-manager