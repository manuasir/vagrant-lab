#-----------------------------------
# WAZUH MANAGER AND API INSTALLATION 
#-----------------------------------

# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools ntp -y

# Install git and zip
yum install git zip -y

#install wget
yum install wget -y

ntpdate -s time.nist.gov

# Wazuh dev repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# Install Wazuh manager
yum install wazuh-manager-3.7.0 -y

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash - 
yum install nodejs -y 

# Install Wazuh API
yum install wazuh-api-3.7.0 -y

#------------------------------
# SPLUNK FORWARDER INSTALLATION
#------------------------------

# download splunkforwarder
wget -O splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.3&product=universalforwarder&filename=splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm&wget=true'

# install splunkforwarder
yum install splunkforwarder-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm -y

# props.conf
curl -so /opt/splunkforwarder/etc/system/local/props.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/props.conf

# inputs.conf
curl -so /opt/splunkforwarder/etc/system/local/inputs.conf https://raw.githubusercontent.com/wazuh/wazuh/3.6/extensions/splunk/inputs.conf

# set hostname
sed -i "s:MANAGER_HOSTNAME:$(hostname):g" /opt/splunkforwarder/etc/system/local/inputs.conf

# add admin user
touch /opt/splunkforwarder/etc/system/local/user-seed.conf

cat > /opt/splunkforwarder/etc/system/local/user-seed.conf <<\EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

# accept license
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --auto-ports --no-prompt

# change default port 8089 to 8090, 8089 used by splunk and accept license
/opt/splunkforwarder/bin/splunk set splunkd-port 8055 -auth admin:changeme

# forward to index
/opt/splunkforwarder/bin/splunk add forward-server 172.16.1.5:9997 -auth admin:changeme

# enable splunkforwarder at boot
/opt/splunkforwarder/bin/splunk enable boot-start

# restart service
/opt/splunkforwarder/bin/splunk restart

# ----------------------------------------------------
# SPLUNK INDEXER AND WAZUH APP FOR SPLUNK INSTALLATION 
# ----------------------------------------------------

# download splunk
wget -O splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.3&product=splunk&filename=splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm&wget=true'

# install splunk
yum install splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm -y

# create credential file
touch /opt/splunk/etc/system/local/user-seed.conf

# add admin user
cat > /opt/splunk/etc/system/local/user-seed.conf <<\EOF
[user_info]
USERNAME = admin
PASSWORD = changeme
EOF

# clone app
git clone https://github.com/wazuh/wazuh-splunk

# install app
cp -R ./wazuh-splunk/SplunkAppForWazuh/ /opt/splunk/etc/apps/

# start splunk
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt

# enable splunk at boot
/opt/splunk/bin/splunk enable boot-start

# restart 
#/opt/splunk/bin/splunk start

#----------------------
# ENABLE WAZUH SERVICES
#----------------------

# Enable Wazuh services
systemctl daemon-reload
systemctl enable wazuh-manager
systemctl enable wazuh-api

# Run Wazuh manager and Wazuh API
systemctl restart wazuh-manager
systemctl restart wazuh-api

echo "Listening authd..."

/var/ossec/bin/ossec-authd -i 