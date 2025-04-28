#!/bin/bash

# define the networks
virsh net-define k8s-cp-net.xml
virsh net-define k8s-egw-blue-net1.xml
virsh net-define k8s-egw-blue-net2.xml
virsh net-define k8s-egw-green-net1.xml
virsh net-define k8s-egw-green-net2.xml

virsh net-define k8s-wkr0-net.xml

# start the networks
virsh net-start k8s-cp-net
virsh net-start k8s-egw-blue-net1
virsh net-start k8s-egw-blue-net2
virsh net-start k8s-egw-green-net1
virsh net-start k8s-egw-green-net2
virsh net-start k8s-wkr0-net

# verify the networks
virsh net-list --all

# define nodes
virsh define k8s-cp-node.xml
virsh define k8s-egw-blue-node.xml
virsh define k8s-egw-green-node.xml
virsh define k8s-wkr0-node.xml

# start the nodes
echo "Starting control plane node..."
virsh start k8s-cp

sleep 5
echo "Starting egress gateway nodes..."
virsh start k8s-egw-blue
virsh start k8s-egw-green

sleep 5
echo "Starting worker node..."
virsh start k8s-wkr0

# verify the nodes
virsh list --all
