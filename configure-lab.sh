#! /bin/bash

export LC_TYPE="UTF-8"
export LANG="en-US.UTF-8"
export LC_ALL="C"

# Source Golbal Variables
source vars.sh

# Become 'admin' user
source admin-openrc

# Create standard Compute flavors
openstack flavor create "m1.tiny" --id 1 --ram 512 --disk 1 --vcpus 1
openstack flavor create "m1.small" --id 2 --ram 2048 --disk 20 --vcpus 1
openstack flavor create "m1.medium" --id 3 --ram 4096 --disk 40 --vcpus 2
openstack flavor create "m1.large" --id 4 --ram 8192 --disk 80 --vcpus 4
openstack flavor create "m1.xlarge" --id 5 --ram 16384 --disk 160 --vcpus 8

# Create provider network and subnet
openstack network create --project "admin" --share --description "Provider Network - shared and external" --external --provider-network-type $PROVIDER_NETWORK_TYPE --provider-physical-network $PROVIDER_PHYSICAL_NETWORK provider
openstack subnet create --project "admin" --network provider --subnet-range $PROVIDER_SUBNET_RANGE --allocation-pool start=$PROVIDER_SUBNET_ALLOCATION_START,end=$PROVIDER_SUBNET_ALLOCATION_END --dns-nameserver $PROVIDER_SUBNET_DNS_SERVER --gateway $PROVIDER_SUBNET_GATEWAY provider_subnet

# Create public network and subnet
openstack network create --project "admin" --share --description "Public Network - shared" public
openstack subnet create --project "admin" --network public --subnet-range $PUBLIC_SUBNET_RANGE --allocation-pool start=$PUBLIC_SUBNET_ALLOCATION_START,end=$PUBLIC_SUBNET_ALLOCATION_END --dns-nameserver $PUBLIC_SUBNET_DNS_SERVER --gateway $PUBLIC_SUBNET_GATEWAY public_subnet

# Create public-ns-router
openstack router create --project "admin" --description "Public North-South Router" public-ns-router
openstack router set --external-gateway provider public-ns-router
openstack router add subnet public-ns-router public_subnet

# Create container1 Swift container in admin Project
openstack container create container1

# Set up bugs Project - 2>&1 > /dev/null
openstack project create --domain default --description 'Lab 18 - Project "bugs"' bugs
openstack user create --description "The wisest of them all" --project "bugs" --password $SHERLOCK_PASS sherlock
openstack role add --project "bugs" --user "sherlock" user
openstack quota set --volumes 1 bugs
openstack network create --project "bugs" incognito
openstack subnet create --project "bugs" --network incognito --subnet-range $INCOGNITO_SUBNET_RANGE --allocation-pool start=$INCOGNITO_SUBNET_ALLOCATION_START,end=$INCOGNITO_SUBNET_ALLOCATION_END --dns-nameserver $INCOGNITO_SUBNET_DNS_SERVER --gateway $INCOGNITO_SUBNET_GATEWAY incognito_subnet
openstack volume create --project "bugs" --size 1 --description "Why is it here?" surprise
openstack server create --project "bugs" --image "cirros" --flavor "m1.tiny" --network "incognito" bad-luck

# Prepare configuration for demo Project
source demo-openrc

# Create private network and subnet in demo Project
openstack network create --description "Demo private network" private
openstack subnet create --network private --subnet-range $PRIVATE_SUBNET_RANGE --allocation-pool start=$PRIVATE_SUBNET_ALLOCATION_START,end=$PRIVATE_SUBNET_ALLOCATION_END --dns-nameserver $PRIVATE_SUBNET_DNS_SERVER --gateway $PRIVATE_SUBNET_GATEWAY private_subnet

# Create demo_NS_router
openstack router create --description "Demo North-South Router" demo_NS_router
openstack router set --external-gateway provider demo_NS_router
openstack router add subnet demo_NS_router private_subnet

# Create demo_vol Volume in demo Project
openstack volume create --size 1 demo_vol

# Create demo_sg Security Group and Rules
openstack security group create demo_sg
openstack security group rule create --protocol icmp --ethertype "IPv4" demo_sg
openstack security group rule create --protocol tcp --dst-port "22:22" --ethertype "IPv4" demo_sg

# Create keypair demo_kp in demo Project
openstack keypair create demo_kp > demo_kp.pem
