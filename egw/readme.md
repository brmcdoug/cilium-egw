## HA and health checks

To add nodes to cluster:
```
kubeadm token create --print-join-command
```

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

2. Install prometheus operator to match Adobe setup:
```
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
```

3. Helm upgrade or install 
```
helm upgrade cilium isovalent/cilium --version 1.17.5  --namespace kube-system -f  helm-values-HA.yaml 


helm install cilium isovalent/cilium --version 1.17.5  --namespace kube-system -f helm-values-HA.yaml 
```

4. Check helm values and that all Cilium agent pods are up
```
helm get values cilium -n kube-system
kubectl get pods -n kube-system
```

5. Add the prometheus-community Helm repo
```
helm repo update
```

6. Install kube-prometheus-stack
```
kubectl create namespace monitoring
```

```
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.enabled=false \
  --set alertmanager.enabled=false \
  --set pushgateway.enabled=false \
  --set serverFiles.prometheus.yml.scrape_configs[0].job_name=kubernetes-pods \
  --set serverFiles.prometheus.yml.scrape_configs[0].kubernetes_sd_configs[0].role=pod \
  --set serverFiles.prometheus.yml.scrape_configs[0].relabel_configs[0].source_labels[0]=__meta_kubernetes_pod_annotation_prometheus_io_scrape \
  --set serverFiles.prometheus.yml.scrape_configs[0].relabel_configs[0].action=keep \
  --set serverFiles.prometheus.yml.scrape_configs[0].relabel_configs[0].regex=true
  ```

verify
```
kubectl get servicemonitors -A
```

7. label k8s nodes to both be egressnode=blue
```
kubectl label node k8s-egw-blue1 egressnode=blue
kubectl label node k8s-egw-blue2 egressnode=blue
kubectl label node k8s-egw-green1 egressnode=green
kubectl label node k8s-egw-green2 egressnode=green
```

or

8. unlabel then re-label green node so we can add to blue HA GW
```
kubectl label node k8s-egw-green egressnode-
kubectl label node k8s-egw-green egressnode=blue
```

9. [12-egw-blue-HA.yaml](./12-egw-blue-HA.yaml) CRD
```yaml
  egressGroups:
    - nodeSelector:
        matchLabels:
          egressnode: "blue"
      maxGatewayNodes: 2  # Allow both nodes to be active
```

10. [21-bgp-cluster-blue.yaml](./21-bgp-cluster-blue.yaml) CRD - not new config, just highlighting it:
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

9. Apply EGW and BGP CRDs in numbered order
```
./apply.sh
```

10. Verify EGW:
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

1.  cleanup old EGW if any:
```
kubectl delete isovalentegressgatewaypolicies egress-blue
kubectl get isovalentegressgatewaypolicies
```

1.   Annotate EGW nodes to set BGP router-id (if needed)
```
kubectl annotate node k8s-egw-green cilium.io/bgp-virtual-router.65001="router-id=10.10.21.2"
kubectl annotate node k8s-egw-blue cilium.io/bgp-virtual-router.65001="router-id=10.10.23.2"
```

1.    Verify BGP peer session established and Cilium is advertising the VIP route:
```
cilium bgp peers
cilium bgp routes
```

1.  update helm values (if needed)
```
helm upgrade cilium isovalent/cilium --namespace kube-system -f helm-values-test.yaml 
```

```
kubectl get isovalentegressgatewaypolicies egress-blue -o yaml
```




15.  Test connectivity to DCI/Blue 10.0.0.0/8 
```
kubectl exec -it -n testns testpod1 -- ping 10.0.0.5 -c 2
```

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


