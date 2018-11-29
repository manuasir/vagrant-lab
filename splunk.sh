
# Remove firewalld
yum remove firewalld -y -q

# Install net-tools, wget, git
yum install net-tools wget git -y -q

# download splunk
wget -O splunk-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.1&product=splunk&filename=splunk-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm&wget=true'

# install splunk
yum install splunk-7.2.1-be11b2c46e23-linux-2.6-x86_64.rpm -y

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

# restart splunk
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt

# restart 
/opt/splunk/bin/splunk start