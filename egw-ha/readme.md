## HA and health checks

1. Edits to [helm values](./helm-values-HA.yaml) - base HA and healthcheck config

```yaml
  egressGatewayHA:
    enabled: true
    healthcheckTimeout: 1s
```

2. socketTermination - per Isov docs: *This is a limited feature and is only suitable for production environments in specific scenarios. Consult Isovalent Customer Support before using it.*
```yaml
    socketTermination:
      enabled: false
```

2. Helm upgrade
```
helm upgrade cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f  helm-values-HA.yaml 
```

3. Check helm values and that all Cilium agent pods are up
```
helm get values cilium -n kube-system
kubectl get pods -n kube-system
```

4. label k8s nodes to both be egressnode=blue
```
kubectl label node k8s-egw-blue egressnode=blue
kubectl label node k8s-egw-blue2 egressnode=blue
```

1. [12-egw-blue-HA.yaml](./12-egw-blue-HA.yaml) CRD
```yaml
  egressGroups:
    - nodeSelector:
        matchLabels:
          egressnode: "blue"
      maxGatewayNodes: 2  # Allow both nodes to be active
```

1. [21-bgp-cluster-blue.yaml](./21-bgp-cluster-blue.yaml) CRD - not new config, just highlighting it:
```yaml
    peers:
    - name: "DCI-1"
      peerASN: 65000
      peerAddress: 10.27.245.44
      peerConfigRef:
        name: "blue-peer"
    - name: "DCI-2"
      peerASN: 65000
      peerAddress: 10.27.245.45
      peerConfigRef:
        name: "blue-peer"
```

1. Apply EGW and BGP CRDs in numbered order
```
./apply.sh
```

1.  Verify EGW:
```
kubectl get node -l egressnode=blue
kubectl get IsovalentEgressGatewayPolicy -oyaml
kubectl get isovalentegressgatewaypolicies egress-blue -o yaml
```

Output:
```yaml
  groupStatuses:
  - activeGatewayIPs:
    - 10.10.11.2
    - 10.10.13.2
    egressIPByGatewayIP:
      10.10.11.2: 10.27.248.2
      10.10.13.2: 10.27.248.3
    healthyGatewayIPs:
    - 10.10.11.2
    - 10.10.13.2
```

Notes:

- Annotate EGW nodes to set BGP router-id (if needed)
```
kubectl annotate node k8s-egw-green cilium.io/bgp-virtual-router.65001="router-id=10.10.21.2"
kubectl annotate node k8s-egw-blue cilium.io/bgp-virtual-router.65001="router-id=10.10.23.2"
```

- Verify BGP peer session established and Cilium is advertising the VIP route:
```
cilium bgp peers
cilium bgp routes
```


