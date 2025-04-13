## Cilium Egress Gateway Lab

Table of Contents

1. [Install Cilium](#install-cilium)
2. [Install Cilium BGP](#install-cilium-bgp)
3. [Install Cilium BGP](#install-cilium-bgp)
4. [Install Cilium BGP](#install-cilium-bgp)
5. [Install Cilium BGP](#install-cilium-bgp)

### Topology

Containerlab network topology:
- Two Nexus 9000v spine nodes
- Three Nexus 9000v leaf nodes
- One XRd DCI node

Ubuntu 22.04 VMs attached to the containerlab leaf nodes:
- k8s-cp - kubernetes control plane node
- k8s-wkr0 - kubernetes worker node
- k8s-wkr1 - kubernetes worker node
- k8s-egw - kubernetes/cilium egress gateway node

![Lab Topology](./diagrams/topology.png)

### cilium-bgpv2 directory
- yaml files for deploying Cilium Enterprise CNI, BGP, and Egress Gateway

### nx-config directory

- Nexus 9000v configurations
- Nexus nodes will boot with these configs on containerlab startup

### vm-config directory

- virsh XML files for defining linux bridge networks to interconnect the VMs with containerlab routers
- virsh XML files defining the VMs themselves
- etc/netplan files defining the VMs' network interfaces and routes

### Instructions

1. Acquire or construct Ubuntu 22.04 VMs 
2. Define VM networks and nodes
```
cd vm-config
sudo ./virsh-define.sh
```

3. Define and launch VMs with Virsh/Libvirt 
```
cd vm-config
./launch.sh
```

4. Install Kubernetes on the VMs [Instructions](xtras/k8s-install.md)
5. 

6. label worker node
```
kubectl label node cluster00-wkr00 egress-node=green
```

If you need to remove the label:
```
kubectl label node cluster00-wkr00 egress-node-
```

2. install cilium, and verify the installation
```
helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f cilium-ent.yaml 
```
```
helm get values cilium -n kube-system
```

3. deploy namespace and pods
```
kubectl apply -f 10-ns-pods.yaml
```

4. apply egress policy
```
kubectl apply -f 10-egw-policy.yaml
```

5. verify egress policy
```
kubectl edit IsovalentEgressGatewayPolicy egress-green
```

6. annotate egw node to force bgp router id
```
kubectl annotate node cluster00-wkr00 cilium.io/bgp-virtual-router.65010="router-id=10.10.21.2"
```

7. add host route on worker EGW node
```
sudo ip route add 192.150.9.124/32 dev ens4
```

8. apply bgp config
```
kubectl apply -f 20-bgp-peering.yaml
```

9. check bgp peers
```
cilium bgp peers
cilium bgp peers --node cluster00-wkr00
```


## appendix, notes


### uninstall
```
helm uninstall cilium -n kube-system
```

```
helm upgrade cilium isovalent/cilium --namespace kube-system    --reuse-values    --set egressGateway.enabled=true --set egressGateway.installRoutes=true   --set bpf.masquerade=true    --set kubeProxyReplacement=true
```

## List all CRDs related to Isovalent
```
kubectl get crd | grep isovalent
```

# Get detailed information about the IsovalentBGPAdvertisement CRD
```
kubectl get crd isovalentbgpadvertisements.isovalent.com -o yaml
```

# Get detailed information about the IsovalentEgressGatewayPolicy CRD
```
kubectl get crd isovalentegressgatewaypolicies.isovalent.com -o yaml
```


# Get the schema in a more readable format
```
kubectl explain isovalentbgpadvertisement.spec
kubectl explain isovalentbgpadvertisement.spec.advertisements
```

# Get the schema in a more readable format
```
kubectl explain isovalentegressgatewaypolicy.spec
kubectl explain isovalentegressgatewaypolicy.spec.selectors
```

```
kubectl get isovalentegressgatewaypolicies -o yaml
```