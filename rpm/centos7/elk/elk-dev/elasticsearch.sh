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
/var/ossec/bin/agent-auth -m 172.16.1.2 -A elasticsearch-ag
sed -i 's:MANAGER_IP:172.16.1.2:g' /var/ossec/etc/ossec.conf

# Enable and restart the Wazuh agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl restart wazuh-agent

# Install Java 8
if which java ; then
	echo "Java already installed"
else
	curl -Lo jre-8-linux-x64.rpm --header "Cookie: oraclelicense=accept-securebackup-cookie" "https://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jre-8u181-linux-x64.rpm"
	rpm -qlp jre-8-linux-x64.rpm > /dev/null 2>&1 && echo "Java package downloaded successfully" || echo "Java package did not download successfully"
	yum -y install jre-8-linux-x64.rpm
	rm -f jre-8-linux-x64.rpm
fi

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

# Install Logstash
yum install elasticsearch-6.4.2 logstash-6.4.2 -y

# Enable Elastic services
systemctl daemon-reload
systemctl enable elasticsearch
systemctl enable logstash

# Configure Elasticsearch master node
cat > /etc/elasticsearch/elasticsearch.yml << 'EOF'
network.host: 172.16.1.4
cluster.name: "my-cluster"
node.name: "es-node-1"
node.master: true
discovery.zen.ping.unicast.hosts: ["172.16.1.4"]
EOF

# Correct owner for Elasticsearch directories
chown elasticsearch:elasticsearch -R /etc/elasticsearch
chown elasticsearch:elasticsearch -R /usr/share/elasticsearch
chown elasticsearch:elasticsearch -R /var/lib/elasticsearch

# Run Elasticsearch
systemctl restart elasticsearch

# Wait for Elasticsearch
until $(curl "http://172.16.1.4:9200/?pretty" --max-time 2 --silent --output /dev/null); do 
	echo "Waiting for Elasticsearch..."
	sleep 2
done

# Insert the template
curl https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/elasticsearch/wazuh-elastic6-template-alerts.json -s | curl -s -XPUT 'http://172.16.1.4:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-

# Logstash remote configuration
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/3.7/extensions/logstash/01-wazuh-remote.conf

sed -i 's#localhost:9200#172.16.1.4:9200#g' /etc/logstash/conf.d/01-wazuh.conf

# Run Logstash
systemctl restart logstash