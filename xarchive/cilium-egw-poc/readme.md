## quick instructions to convert to BGPv2

This is the procedure I followed to convert my non-working BGPv1 setup to BGPv2. Note, I also rebuilt the helm values file 

1. Delete existing Cilium CRDs and uninstall Cilium via helm uninstall:
```
kubectl delete -f <filename.yaml>
helm uninstall <release name> -n kube-system
helm uninstall cilium -n kube-system
```

2. Re-install Cilium using updated helm values format - note, BGP Control Plane has been moved to the "Enterprise" section in the yaml file [link](./helm-values.yaml#L13)
```
helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f  helm-values.yaml 

# in my lab:

helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f  helm-values-test.yaml

```

3. Check helm values and that all Cilium agent pods are up
```
helm get values cilium -n kube-system
kubectl get pods -n kube-system
```

4. label EGW nodes:
```
kubectl label node k8s-egw-green egressnode=green
kubectl label node k8s-egw-blue egressnode=blue
```

### untested - re-apply old load balancer/service and ingress BGP CRDs

 - Note: as of 4/24/2025 ingress yaml file translation is still under construction...however, if ingress is working with BGPv1 then translation to BGPv2 is not urgent

 - Note: as of 4/27/2025 testing I've not applied any ingress CRDs, only egress blue and green, which are both working

### reinstall egress GW with egress BGPv2

4. Apply Cilium egress gateway policy yaml
```
kubectl apply -f 10-egw-green.yaml
kubectl apply -f 11-egw-blue.yaml
```

5. Verify EGW:
```
kubectl get node -l egressnode=green
kubectl get node -l egressnode=blue
kubectl get IsovalentEgressGatewayPolicy -oyaml
```

6. Verify VIP/2ndary IP address on egress gateway worker node
```
ip addr show dev ens224
```

In my lab:
```
cisco@k8s-egw:~$ ip addr show dev ens5
4: ens5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:ab:00:00:03 brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    inet 10.10.21.2/24 brd 10.10.21.255 scope global ens5
       valid_lft forever preferred_lft forever
    inet 192.150.9.124/32 scope global ens5          <-----------
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:abff:fe00:3/64 scope link 
       valid_lft forever preferred_lft forever
```

7. Apply BGP cluster config:
```
kubectl apply -f 20-bgp-cluster-green.yaml 
kubectl apply -f 21-bgp-cluster-blue.yaml
```

8. Annotate EGW nodes to set BGP router-id:
```
kubectl annotate node k8s-egw-green cilium.io/bgp-virtual-router.65001="router-id=10.10.21.2"
kubectl annotate node k8s-egw-blue cilium.io/bgp-virtual-router.65001="router-id=10.10.23.2"
```

9.  Apply BGP peer config (this config is very short so I put green, blue, and red in one file):
```
kubectl apply -f 30-bgp-peer.yaml 
```

1o. Apply BGP advertisement
```
kubectl apply -f 40-bgp-advert-green.yaml 
kubectl apply -f 41-bgp-advert-blue.yaml 
```

11.  Verify BGP peer session established and Cilium is advertising the VIP route:
```
cilium bgp peers
cilium bgp routes
```

Example output:
```
cisco@k8s-cp:~/cilium-egw/cilium-egw-poc$ cilium bgp peers
Node            Local AS   Peer AS   Peer Address   Session State   Uptime   Family         Received   Advertised
k8s-egw-blue    65001      65000     10.27.245.44   established     20m58s   ipv4/unicast   5      1    
                65001      65000     10.27.245.45   active          0s       ipv4/unicast   0      0    
k8s-egw-green   65001      65000     10.27.245.46   established     12m30s   ipv4/unicast   6      1    
                65001      65000     10.27.245.47   active          0s       ipv4/unicast   0      0    
cisco@k8s-cp:~/cilium-egw/cilium-egw-poc$ cilium bgp routes
(Defaulting to `available ipv4 unicast` routes, please see help for more options)

Node            VRouter   Prefix             NextHop   Age     Attrs
k8s-egw-blue    65001     10.27.248.0/32     0.0.0.0   21m9s   [{Origin: i} {Nexthop: 0.0.0.0}]   
k8s-egw-green   65001     192.150.9.124/32   0.0.0.0   9m39s   [{Origin: i} {Nexthop: 0.0.0.0}]  
```

12.  Test connectivity to DCI/Blue 10.0.0.0/8 
```
kubectl exec -it -n testns testpod1 -- ping 10.0.0.5 -c 2
```

12.  Test connectivity to DCI/Green Internet
```
kubectl exec -it -n testns testpod1 -- ping 5.5.5.5 -c 2
```

14.  Verify outbound NAT/PAT - I run a tcpdump on the egress gateway worker node 'ens224' equivalent:
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