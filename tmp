# -*- mode: ruby -*-
# vi: set ft=ruby :

servers=[
  {
    :hostname => "coa-lab",
    :box => "ubuntu/xenial64",
    :ram => 8192,
    :cpu => 2,
    :script => "bash /vagrant/virtualbox-guest-setup.sh"
  }
]

# Read Network Configuration parameters from 'vars.sh'
# This VM requires two VirtualBox networks:
# - Host-only Network to facilitate access to VM with CONTROLLER_IP
# - NAT Network to facilitate Provider Network for OpenStack

IO.foreach('vars.sh') do |line|
  var, value = line.split('=')
  case var
  when 'CONTROLLER_IP'
    CONTROLLER_IP = value[1...-2]
  when 'CONTROLLER_NETMASK'
    CONTROLLER_NETMASK = value[1...-2]
  when 'PROVIDER_SUBNET_RANGE'
    PROVIDER_SUBNET_RANGE = value[1...-2]
  end
end

# ProviderNetwork defines name of VirtualBox NAT Network used to implement Provider network
ProviderNetwork = "ProviderNetwork"

# Set name of VBoxManage binary depending on Host Platform
$VBoxManage_cmd = 'VBoxManage'
if RUBY_PLATFORM.include? 'mingw'
  $VBoxManage_cmd = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
elsif RUBY_PLATFORM.include? 'darwin'
  # $VBoxManage_cmd =
end

# Delete Provider Network when bringing VM up
if ARGV[0] == "up"
  require 'open3'
  stdout, stderr, status = Open3.capture3($VBoxManage_cmd,"natnetwork","list", ProviderNetwork)
  if stdout.include? ProviderNetwork
    puts "Provider Network exists. Removing.."
    system($VBoxManage_cmd, "natnetwork", "remove", "--netname", ProviderNetwork)
  end
end

$POST_UP_MESSAGE = <<EOF
--------------------------------------------------------------------------------------

Vagrant has concluded basic configuration of 'coa-lab' VM
The 'coa-lab' VM is currently rebooting.
Reboot progress can be monitored in "Oracle VM VirtualBox Manager" window,
click on "pike-coa-lab...." VM and select "Details"

Please run "vagrant ssh' when 'coa-lab' VM finishes reboot,
then execute following commands at VM Shell Prompt:

sudo su
bash install_openstack.sh

---------------------------------------------------------------------------------------
EOF

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  servers.each do |machine|
    config.vm.define machine[:hostname] do |node|
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.network "forwarded_port", guest: 80, host: 8080
      node.vm.network "forwarded_port", guest: 6080, host: 6080
      node.vm.network "private_network", ip: CONTROLLER_IP, netmask: CONTROLLER_NETMASK
      node.vm.provider "virtualbox" do |vb|
#        vb.gui = true
        vb.customize ["modifyvm", :id, "--memory", machine[:ram], "--cpus", machine[:cpu]]
        vb.customize ["natnetwork", "add", "--netname", ProviderNetwork, "--network", PROVIDER_SUBNET_RANGE, "--enable", "--dhcp", "off"]
        vb.customize ["modifyvm", :id, "--nic3", "natnetwork", "--nat-network3", "ProviderNetwork", "--nicpromisc3", "allow-all"]
        controller_name = 'SCSI'
        file_to_disk = File.realpath( "." ).to_s + '/openstack_data.vdi'
        vb.customize ['createhd', '--filename', file_to_disk, '--size', 50 * 1024, '--format', 'VDI']
        vb.customize ['storageattach', :id, '--storagectl', controller_name, '--type', 'hdd', '--port', 2, '--medium', file_to_disk]
      end
      node.vm.provision "shell", inline: machine[:script], privileged: true, run: "once"
      node.vm.post_up_message = $POST_UP_MESSAGE
    end
  end
end
