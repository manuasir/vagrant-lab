Vagrant.configure("2") do |config|

	config.vm.define "master" do |master|
  		master.vm.box = "centos/7"
  		master.vm.provision :shell, path: "master.sh"
  		master.vm.network "public_network", ip: "192.168.1.193", bridge: 'wlp2s0'
		master.vm.provider "virtualbox" do |pmv|
	      pmv.memory = 4096
	      pmv.cpus   = 4
	    end
	end

	config.vm.define "client" do |client|
	  client.vm.box = "centos/7"
	  client.vm.provision :shell, path: "client.sh"
	  client.vm.network "public_network", ip: "192.168.1.194", bridge: 'wlp2s0'
	end

	config.vm.define "agent1" do |agent1|
	  agent1.vm.box = "centos/7"
	  agent1.vm.provision :shell, path: "agent.sh"
	  agent1.vm.network "public_network", ip: "192.168.1.195", bridge: 'wlp2s0'
  	end

	config.vm.define "agent2" do |agent2|
	  agent2.vm.box = "centos/7"
	  agent2.vm.provision :shell, path: "agent.sh"
	  agent2.vm.network "public_network", ip: "192.168.1.196", bridge: 'wlp2s0'
  	end

	config.vm.define "agent3" do |agent3|
	  agent3.vm.box = "centos/7"
	  agent3.vm.provision :shell, path: "agent.sh"
	  agent3.vm.network "public_network", ip: "192.168.1.197", bridge: 'wlp2s0'
  	end

	config.vm.define "agent4" do |agent4|
	  agent4.vm.box = "centos/7"
	  agent4.vm.provision :shell, path: "agent.sh"
	  agent4.vm.network "public_network", ip: "192.168.1.198", bridge: 'wlp2s0'
  	end

	config.vm.define "agent5" do |agent5|
	  agent5.vm.box = "centos/7"
	  agent5.vm.provision :shell, path: "agent.sh"
	  agent5.vm.network "public_network", ip: "192.168.1.199", bridge: 'wlp2s0'
  	end
end
