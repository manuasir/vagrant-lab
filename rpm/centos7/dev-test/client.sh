# Remove firewalld
yum remove firewalld gcc -y -q

# Install tools
yum install net-tools ntp curl wget git make gcc policycoreutils-python automake autoconf libtool -y -q
ntpdate -s time.nist.gov

# Wazuh repository
echo -e '[wazuh_pre_release]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages-dev.wazuh.com/pre-release/yum/\nprotect=1' | tee /etc/yum.repos.d/wazuh_pre.repo

# Install Wazuh manager
yum install wazuh-manager -y -q

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y -q

# download splunkforwarder
wget -O splunkforwarder-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.1&product=universalforwarder&filename=splunkforwarder-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm&wget=true'

# install splunkforwarder
yum install splunkforwarder-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm -y

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

# systemctl daemon-reload

# systemctl enable wazuh-manager


# Wazuh cluster configuration
# sed -i 's:<node_name>node01</node_name>:<node_name>node02</node_name>:g' /var/ossec/etc/ossec.conf
# sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
# sed -i 's:<node>NODE_IP</node>:<node>172.16.1.4</node>:g' /var/ossec/etc/ossec.conf
# sed -i 's:<node_type>master</node_type>:<node_type>client</node_type>:g' /var/ossec/etc/ossec.conf
# sed -i -e '/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g' /var/ossec/etc/ossec.conf

# Run Wazuh manager
#ystemctl restart wazuh-manager