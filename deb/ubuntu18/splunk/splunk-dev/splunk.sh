# Remove firewalld
apt update

# Install net-tools
apt install net-tools -y

# Install wget
apt install wget -y

# Install git
apt install git -y

# download splunk
wget -O splunk-7.2.0-8c86330ac18-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.2.0&product=splunk&filename=splunk-7.2.0-8c86330ac18-linux-2.6-amd64.deb&wget=true'
# install splunk
dpkg --install splunk-7.2.0-8c86330ac18-linux-2.6-amd64.deb

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