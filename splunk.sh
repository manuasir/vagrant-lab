# Remove firewalld
yum remove firewalld -y

# Install net-tools
yum install net-tools -y

# Install wget
yum install wget -y

# download splunk
wget -O splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.3&product=splunk&filename=splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm&wget=true'

# install splunk
yum install splunk-7.1.3-51d9cac7b837-linux-2.6-x86_64.rpm -y

# clone app
git clone https://github.com/wazuh/wazuh-splunk

# install app
cp -R ./wazuh-splunk/SplunkAppForWazuh/ /opt/splunk/etc/apps/

# restart splunk
/opt/splunk/bin/splunk restart --accept-license