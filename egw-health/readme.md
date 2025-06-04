## HA/Health install doc / notes

I cleaned everything out first

1. Delete existing Cilium CRDs and uninstall Cilium via helm uninstall:
```
kubectl delete -f <filename.yaml>
helm uninstall <release name> -n kube-system
helm uninstall cilium -n kube-system
```

2. Install prometheus operator:
```
kubectl apply -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/bundle.yaml
```

3. Re-install Cilium using updated helm values with serviceMonitor uncommented
```
helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f  helm-values.yaml 
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

6. label EGW nodes:
```
kubectl label node k8s-egw-green egressnode=green
kubectl label node k8s-egw-blue egressnode=blue
```

7. Apply EGW and BGP CRDs in numbered order

8. Verify EGW:
```
kubectl get node -l egressnode=green
kubectl get node -l egressnode=blue
kubectl get IsovalentEgressGatewayPolicy -oyaml
```

9. unlabel then re-label green node so we can add to blue HA GW
```
kubectl label node k8s-egw-green egressnode-
kubectl label node k8s-egw-green egressnode=blue
```
```
cisco@k8s-cp:~/cilium-egw/egw-health$ kubectl get node -l egressnode=blue
NAME            STATUS   ROLES    AGE   VERSION
k8s-egw-blue    Ready    <none>   25m   v1.31.8
k8s-egw-green   Ready    <none>   25m   v1.31.8
```

10. cleanup old EGW if any:
```
kubectl delete isovalentegressgatewaypolicies egress-blue
kubectl get isovalentegressgatewaypolicies
```

11. apply 12-egw-blue-HA.yaml (delete )
```
kubectl apply -f 12-egw-blue-HA.yaml
```

12.  Annotate EGW nodes to set BGP router-id (if needed)
```
kubectl annotate node k8s-egw-green cilium.io/bgp-virtual-router.65001="router-id=10.10.21.2"
kubectl annotate node k8s-egw-blue cilium.io/bgp-virtual-router.65001="router-id=10.10.23.2"
```

13.   Verify BGP peer session established and Cilium is advertising the VIP route:
```
cilium bgp peers
cilium bgp routes
```

14. update helm values (if needed)
```
helm upgrade cilium isovalent/cilium --namespace kube-system -f helm-values-test.yaml 
```

15.  Test connectivity to DCI/Blue 10.0.0.0/8 
```
kubectl exec -it -n testns testpod1 -- ping 10.0.0.5 -c 2
```

1.   Test connectivity to DCI/Green Internet
```
kubectl exec -it -n testns testpod1 -- ping 5.5.5.5 -c 2
```

1.   Verify outbound NAT/PAT - I run a tcpdump on the egress gateway worker node 'ens224' equivalent:
```
tcpdump -ni ens224
```

Example:
```
cisco@topology-host:~$ sudo tcpdump -ni k8s-blue-net2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on k8s-blue-net2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
04:03:59.977032 IP 10.10.23.2.58499 > 10.27.245.44.179: Flags [P.], seq 539837254:539837273, ack 2952658864, win 502, length 19: BGP
04:04:00.187942 IP 10.27.245.44.179 > 10.10.23.2.58499: Flags [.], ack 19, win 31998, length 0
^C
2 packets captured
2 packets received by filter
0 packets dropped by kernel

cisco@topology-host:~$ sudo tcpdump -ni k8s-green-net2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on k8s-green-net2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
04:04:06.627937 IP 192.150.9.124 > 5.5.5.5: ICMP echo request, id 48531, seq 10, length 64
04:04:06.637071 IP 5.5.5.5 > 192.150.9.124: ICMP echo reply, id 48531, seq 10, length 64
04:04:07.634030 IP 192.150.9.124 > 5.5.5.5: ICMP echo request, id 48531, seq 11, length 64
04:04:07.645111 IP 5.5.5.5 > 192.150.9.124: ICMP echo reply, id 48531, seq 11, length 64
04:04:08.628707 IP 192.150.9.124 > 5.5.5.5: ICMP echo request, id 48531, seq 12, length 64
04:04:08.637804 IP 5.5.5.5 > 192.150.9.124: ICMP echo reply, id 48531, seq 12, length 64
```


### Appendix

```
helm uninstall cilium -n kube-system

helm upgrade cilium isovalent/cilium --namespace kube-system -f helm-values-test.yaml 
```