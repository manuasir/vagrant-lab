# Remove firewalld
yum remove firewalld -y

# Install net-tools, git, zip, ntp
yum install net-tools git zip ntp -y
ntpdate -s time.nist.gov

# Wazuh dev repository
echo -e '[wazuh_repo_dev]\ngpgcheck=1\ngpgkey=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/key/GPG-KEY-WAZUH\nenabled=1\nname=EL-$releasever - Wazuh\nbaseurl=https://s3-us-west-1.amazonaws.com/packages.wazuh.com/3.x/yum-dev/\nprotect=1' | tee /etc/yum.repos.d/wazuh_dev.repo

# Install Wazuh agent
yum install wazuh-agent-3.7.0 -y

# Register agent using authd
/var/ossec/bin/agent-auth -m 172.16.1.2 -A kibana-ag
sed -i 's:MANAGER_IP:172.16.1.2:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# Elastic GPG KEY
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch

# Elastic repository
cat > /etc/yum.repos.d/elastic.repo << EOF
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Kibana
yum install kibana-6.4.2 -y

# Enable Elastic services
systemctl daemon-reload
systemctl enable kibana

# Kibana configuration
sed -i 's:\#server.host\: "localhost":server\.host\: "0.0.0.0":g' /etc/kibana/kibana.yml
sed -i 's:#elasticsearch.url:elasticsearch.url:g' /etc/kibana/kibana.yml
sed -i 's#http://localhost:9200#http://172.16.1.4:9200#g' /etc/kibana/kibana.yml

# Install Node.js + Wazuh app from git branch
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
yum install nodejs -y
npm install -g yarn@1.6.0
npm install -g n
n 8.11.4
mv /usr/local/bin/node /usr/bin
mv /usr/local/bin/npm /usr/bin
mv /usr/local/bin/npx /usr/bin
git clone https://github.com/wazuh/wazuh-kibana-app wazuhapp -b 3.7-6.4 --single-branch --depth=1 && cd wazuhapp && yarn && yarn build > /dev/null
mv /home/vagrant/wazuhapp/build/wazuh-3.7.0.zip /tmp
chown kibana:kibana /tmp/wazuh-3.7.0.zip
export NODE_OPTIONS="--max-old-space-size=3072"
sudo -u kibana /usr/share/kibana/bin/kibana-plugin install file:///tmp/wazuh-3.7.0.zip

# Run Kibana
systemctl restart kibana
