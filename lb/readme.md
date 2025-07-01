## Ingress GW and Load Balancing

## Contents
- [Ingress GW and Load Balancing](#ingress-gw-and-load-balancing)
- [Contents](#contents)
  - [kube-proxy replacement and base setup](#kube-proxy-replacement-and-base-setup)
  - [Enterprise ?](#enterprise-)
  - [Client source IP preservation (DSR)](#client-source-ip-preservation-dsr)
  - [Appendix](#appendix)

### kube-proxy replacement and base setup

1. Remove kube-proxy
```
kubectl -n kube-system delete ds kube-proxy
# Delete the configmap as well to avoid kube-proxy being reinstalled during a Kubeadm upgrade (works only for K8s 1.19 and newer)
kubectl -n kube-system delete cm kube-proxy
# Run on each node with root permissions:
iptables-save | grep -v KUBE | iptables-restore
```

2. helm upgrade (we already have kubeProxyReplacement=true)
```
helm upgrade cilium isovalent/cilium --namespace kube-system -f  helm-values-HA.yaml 
```

or
```
helm install cilium isovalent/cilium --namespace kube-system -f  helm-values-LB.yaml
```

```
helm get values cilium -n kube-system
```

3. verify
```
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement

kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
```

### Enterprise ?
```
helm upgrade cilium isovalent/cilium --namespace kube-system --set loadBalancer.acceleration=native --set loadBalancer.mode=maglev
```
```
--set loadBalancer.acceleration=best-effort
```

4. Verify
```
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose | more
```

4. deploy test pods
```
kubectl apply -f nginx-test-dp.yaml
kubectl get pods -l run=my-nginx -o wide
```

5. expost NP
```
kubectl expose deployment my-nginx --type=NodePort --port=80
```

6. test
```
kubectl get svc my-nginx
```

```
cisco@k8s-cp:~/cilium-egw/lb$ kubectl get svc my-nginx
NAME       TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
my-nginx   NodePort   10.96.239.117   <none>        80:31021/TCP   17s
```

7. validate kube-proxy replacement 
```
kubectl -n kube-system exec ds/cilium -- cilium-dbg service list
```

8. create variable and test with simple curls
  
```
node_port=$(kubectl get svc my-nginx -o=jsonpath='{@.spec.ports[0].nodePort}')

curl 127.0.0.1:$node_port
curl 10.10.12.2:$node_port
curl 10.96.239.117:80
```

### Client source IP preservation (DSR)

Note (June 27, 2025): this document covers externalTrafficPolicy. internalTrafficPolicy can be explored in the future.

The POC is not making use of either:
[Selective Service Type Exposure](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#selective-service-type-exposure)
or
[Selective Service Node Exposure]
https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#selective-service-node-exposure


The POC will use [Maglev LB](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#maglev-consistent-hashing) for Consistent Hashing. Maglev consumes a bit more memory than `random`, but with the greater resiliency of consistent backend selection.

Note from AI regarding DSR and backend reply with Service IP:Port:

"When using DSR mode, the backend pods will respond directly to the client using the service's public IP and port as the source address in the response packets.
Here's how it works:
Client → Load Balancer: Client sends packet to service IP (e.g., 10.0.0.100:80)
Load Balancer → Backend: Cilium forwards the packet to a backend pod, but encodes the original service IP/port information in the packet
Backend → Client: The backend pod responds directly to the client using the service IP (10.0.0.100:80) as the source address
This means:
The client sees responses coming from the service IP, not the backend pod's IP
The backend pod is aware it needs to respond with the service IP/port
The load balancer doesn't need to process the return traffic (hence "Direct Server Return")
The MTU reduction is necessary because Cilium needs to encode the service IP/port information in the packet headers so the backend knows how to respond. This is typically a small overhead (a few bytes) but ensures the backend can construct the correct response packet.
This is particularly useful for:
Applications that need to see the original client source IP
Reducing load balancer processing overhead
Maintaining session affinity when needed
The trade-off is the slightly reduced MTU, but for most applications, this is negligible compared to the benefits of DSR."

**DSR will inherit cluster tunnel mode unless specified otherwise**

```
cilium config view | grep tunnel
```
```
cisco@k8s-cp:~/cilium-egw/lb$ cilium config view | grep tunnel
routing-mode                                         tunnel
tunnel-protocol                                      vxlan
tunnel-source-port-range                             0-0
```

1. Helm upgrade to apply Maglev
```
helm upgrade cilium isovalent/cilium  --namespace kube-system -f  helm-values-HA-maglev.yaml  
```

```
helm get values cilium -n kube-system
```

2. label nodes
```
kubectl label node k8s-egw-blue1 ingressnode=blue
kubectl label node k8s-egw-blue2 ingressnode=blue
kubectl label node k8s-egw-green1 ingressnode=green
kubectl label node k8s-egw-green2 ingressnode=green
```

3. Apply IGW and BGP config
```
kubectl apply -f 10-ingress-lb.yaml
kubectl apply -f 11-bgp-advert-ingress-blue.yaml
```

### Appendix

```
kubectl get pods -n kube-system -l k8s-app=cilium -o wide
```



