# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools ntp -y

# Install git and zip
yum install git zip -y

#install wget
yum install wget -y

yum install postfix mailx cyrus-sasl cyrus-sasl-plain -y

ntpdate -s time.nist.gov

# Wazuh dev repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# update yum
yum update wazuh-manager -y

# Install Wazuh manager
yum install wazuh-manager -y

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
yum install nodejs -y 

# Install Wazuh API
yum install wazuh-api -y

#install test dependencies
npm install mocha -g

# clone the Wazuh API repo
cd /tmp/
rm -rf wazuh-api 2> /dev/null
git clone https://github.com/wazuh/wazuh-api
cd wazuh-api

# change API test options
sed -i 's:https:http:g' /tmp/wazuh-api/test/common.js

# install api test dependencies
npm install glob supertest mocha should moment

# Wazuh cluster dependencies
yum install python-setuptools python-cryptography -y

# Configure Wazuh master node
sed -i 's:<node_name>node01</node_name>:<node_name>master</node_name>:g' /var/ossec/etc/ossec.conf
sed -i 's:<key></key>:<key>9d273b53510fef702b54a92e9cffc82e</key>:g' /var/ossec/etc/ossec.conf
sed -i 's:<node>NODE_IP</node>:<node>172.16.1.4</node>:g' /var/ossec/etc/ossec.conf
sed -i -e '/<cluster>/,/<\/cluster>/ s|<disabled>[a-z]\+</disabled>|<disabled>no</disabled>|g' /var/ossec/etc/ossec.conf

# delete last line
sed -i '$ d' /var/ossec/etc/ossec.conf

# agentless
sed -i '/<agentless>/,/<\/agentless>/d' /var/ossec/etc/ossec.conf

# Wazuh repository
cat >> /var/ossec/etc/ossec.conf<<\EOF
<agentless>
    <type>ssh_integrity_check_linux</type>
    <frequency>300</frequency>
    <host>admin@192.168.1.108</host>
    <state>periodic_diff</state>
    <arguments>/etc /usr/bin /usr/sbin</arguments>
</agentless>
EOF

sed -i '/<active-response>/,/<\/active-response>/d' /var/ossec/etc/ossec.conf
# active response
cat >> /var/ossec/etc/ossec.conf<<\EOF
<active-response>
    <disabled>no</disabled>
    <command>host-deny</command>
    <location>defined-agent</location>
    <agent_id>032</agent_id>
    <level>10</level>
    <rules_group>sshd,|pci_dss_11.4,</rules_group>
    <timeout>1</timeout>
</active-response>
EOF

sed -i '/<syslog_output>/,/<\/syslog_output>/d' /var/ossec/etc/ossec.conf

cat >> /var/ossec/etc/ossec.conf<<\EOF
<syslog_output>
    <level>9</level>
    <server>192.168.1.241</server>
</syslog_output>
EOF

sed -i '/<integration>/,/<\/integration>/d' /var/ossec/etc/ossec.conf

cat >> /var/ossec/etc/ossec.conf<<\EOF
<integration>
    <name>virustotal</name>
    <api_key>28b78600394c8100d527e43c5fd185dbaa9742e086085b44c584afd24af310f4</api_key>
    <group>syscheck</group>
    <alert_format>json</alert_format>
    <hook_url></hook_url>
</integration>
EOF

sed -i '/<socket>/,/<\/socket>/d' /var/ossec/etc/ossec.conf

cat >> /var/ossec/etc/ossec.conf<<\EOF
<socket>
    <name>custom_socket</name>
    <location>/var/run/custom.sock</location>
    <mode>tcp</mode>
    <prefix>custom_syslog: </prefix>
</socket>
EOF

# change configuration ossec.conf
sed -i 's:<email_to>recipient@example.wazuh.com</email_to>:<email_to>hello@wazuh.com</email_to>:g' /var/ossec/etc/ossec.conf
sed -i 's:<email_from>ossecm@example.wazuh.com</email_from>:<email_from>wazuh@test.com</email_from>:g' /var/ossec/etc/ossec.conf
sed -i 's:<smtp_server>smtp.example.wazuh.com</smtp_server>:<smtp_server>localhost</smtp_server>:g' /var/ossec/etc/ossec.conf
sed -i 's:<email_notifications>no</email_notifications>:<email_notifications>yes</email_notifications>:g' /var/ossec/etc/ossec.conf
sed -i 's:<use_source_ip>yes</use_source_ip>:<use_source_ip>no</use_source_ip>:g' /var/ossec/etc/ossec.conf

CONTENT="<email_alerts>\n<email_to>you@example.com</email_to>\n<level>4</level>\n<do_not_delay />\n</email_alerts>"

C=$(echo $CONTENT | sed 's/\//\\\//g')
sed "/<\/global>/ s/.*/${C}\n&/" /var/ossec/etc/ossec.conf

# last line
cat >> /var/ossec/etc/ossec.conf<<\EOF
</ossec_config>
EOF

# internal options
cat >> /var/ossec/etc/local_internal_options.conf<<\EOF
wazuh_database.sync_syscheck=1
EOF

cat >> /etc/postfix/main.cf<<\EOF
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt
smtp_use_tls = yes
EOF

echo [smtp.gmail.com]:587 wazuh@test.com:test1234 > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 400 /etc/postfix/sasl_passwd
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
systemctl reload postfix

# Enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-api

# enable modules
/var/ossec/bin/ossec-control enable client-syslog
/var/ossec/bin/ossec-control enable integrator
/var/ossec/bin/ossec-control enable agentless
/var/ossec/bin/ossec-maild
/var/ossec/bin/ossec-authd

# enable experimental features
sed -i 's:config.experimental_features  = false:config.experimental_features  = true:g' /var/ossec/api/configuration/config.js

# Run Wazuh manager and Wazuh API
/var/ossec/bin/ossec-control restart
systemctl restart wazuh-api

echo "Listening authd..."

/var/ossec/bin/ossec-authd -i 