## HA and health checks

I cleaned everything out first and had to rebuild my n9kv topology to include two DCI nodes



1. Delete existing Cilium CRDs and uninstall Cilium via helm uninstall:
```
kubectl delete -f <filename.yaml>
helm uninstall <release name> -n kube-system
helm uninstall cilium -n kube-system
```

2. Install prometheus operator to match Adobe setup:
```
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
```

3. Re-install Cilium using updated helm values with serviceMonitor uncommented
```
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

8. label k8s nodes 
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

9. Apply EGW and BGP CRDs in numbered order
```
./apply.sh
```

10. Verify EGW:
```
kubectl get node -l egressnode=blue
kubectl get IsovalentEgressGatewayPolicy -oyaml
```




