# cilium-egw

### Notes and rough instructions

1. label worker node
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