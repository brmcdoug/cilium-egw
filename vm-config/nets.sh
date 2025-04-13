#!/bin/bash

# define the networks
virsh net-define k8s-cp-net.xml
virsh net-define k8s-egw-net1.xml
virsh net-define k8s-egw-net2.xml
virsh net-define k8s-wkr0-net.xml

# start the networks
virsh net-start k8s-cp-net
virsh net-start k8s-egw-net1
virsh net-start k8s-egw-net2
virsh net-start k8s-wkr0-net

# verify the networks
virsh net-list --all