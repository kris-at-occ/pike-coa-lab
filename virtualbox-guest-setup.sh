#! /bin/bash

# Debug options to enable bash trace with output to file descriptor 2 (common error output)
BASH_XTRACEFD="2"
PS4='$LINENO: '
set -x

export LC_TYPE="UTF-8"
export LANG="en-US.UTF-8"
export LC_ALL="C"

# Set all Global Variables, defined in vars.sh
cp /vagrant/vars.sh /home/vagrant
cp /vagrant/install-openstack.sh /home/vagrant
cp /vagrant/configure-lab.sh /home/vagrant
mkdir -p /home/vagrant/labs
cp /vagrant/labs/* /home/vagrant/labs
source /home/vagrant/vars.sh

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y crudini

crudini --set /etc/default/grub "" GRUB_CMDLINE_LINUX '"net.ifnames=0 biosdevname=0"'
update-grub

cat <<- EOF > /etc/network/interfaces
auto lo0
iface lo inet loopback

auto $INTERNET_INTERFACE_NAME
iface $INTERNET_INTERFACE_NAME inet dhcp

auto $MANAGEMENT_INTERFACE_NAME
iface $MANAGEMENT_INTERFACE_NAME inet static
  address $CONTROLLER_IP
  netmask $CONTROLLER_NETMASK
  dns-nameservers $CONTROLLER_NAMESERVERS

auto $PROVIDER_INTERFACE_NAME
iface $PROVIDER_INTERFACE_NAME inet manual
  up ip link set dev $PROVIDER_INTERFACE_NAME up
  down ip link set dev $PROVIDER_INTERFACE_NAME down
EOF

pvcreate /dev/sdc
vgcreate os-data /dev/sdc
lvcreate -L 2G -n swift11 os-data
lvcreate -L 2G -n swift12 os-data
lvcreate -L 2G -n swift21 os-data
lvcreate -L 2G -n swift22 os-data
lvcreate -L 30G -n cinder-vols1 os-data
lvcreate -L 5G -n cinder-vols2 os-data

reboot
