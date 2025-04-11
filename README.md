# cilium-egw

1. label node
```
kubectl label node cluster00-wkr00 egress-node=green
kubectl label node cluster00-wkr00 egress-node-
```

2. install cilium
```
helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f cilium-ent.yaml 
```
```

helm upgrade cilium isovalent/cilium --namespace kube-system    --reuse-values    --set egressGateway.enabled=true --set egressGateway.installRoutes=true   --set bpf.masquerade=true    --set kubeProxyReplacement=true

helm get values cilium -n kube-system
```
1. apply egress policy
```
kubectl apply -f 01-egw-policy.yaml
```

1. verify egress policy
```
kubectl edit IsovalentEgressGatewayPolicy egress-green
```

kubectl annotate node cluster00-wkr00 cilium.io/bgp-virtual-router.65010="router-id=10.10.11.2"

1. add host route on worker EGW node
```
sudo ip route add 192.150.9.124/32 dev ens4
```

1. apply bgp config
```
kubectl apply -f 10-bgp-cluster.yaml
kubectl apply -f 11-bgp-peer.yaml
```

1. check bgp peers
```
cilium bgp peers --node cluster00-wkr00
```
# List all CRDs related to Isovalent
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


### uninstall
```
helm uninstall cilium -n kube-system
```
