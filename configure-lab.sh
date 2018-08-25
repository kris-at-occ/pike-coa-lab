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
openstack network create --project "admin" --share --description "Public Provider Network - shared and external" --external --provider-network-type $PROVIDER_NETWORK_TYPE --provider-physical-network $PROVIDER_PHYSICAL_NETWORK provider
openstack subnet create --project "admin" --network provider --subnet-range $PROVIDER_SUBNET_RANGE --allocation-pool start=$PROVIDER_SUBNET_ALLOCATION_START,end=$PROVIDER_SUBNET_ALLOCATION_END --dns-nameserver $PROVIDER_SUBNET_DNS_SERVER provider

# Create demo-net network and subnet
openstack network create --project "demo" --description "Demo private network" demo-net
openstack subnet create --project "demo" --network demo-net --subnet-range $DEMO_NET_SUBNET_RANGE --allocation-pool start=$DEMO_NET_SUBNET_ALLOCATION_START,end=$DEMO_NET_SUBNET_ALLOCATION_END --dns-nameserver $DEMO_NET_SUBNET_DNS_SERVER demo-net

# Create demo-ns-router
openstack router create --project demo --description "Demo North-South Router" demo-ns-router
openstack router set --external-gateway provider demo-ns-router
openstack router add subnet demo-ns-router demo-net
