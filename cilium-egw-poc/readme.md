## quick instructions to convert to BGPv2

This is the procedure I followed to convert my non-working BGPv1 setup to BGPv2. Note, I also rebuilt the helm values file 

1. Delete existing Cilium CRDs and uninstall Cilium via helm uninstall:
```
kubectl delete -f <filename.yaml>
helm uninstall <release name> -n kube-system
```

2. Re-install Cilium using updated helm values format - note, BGP Control Plane has been moved to the "Enterprise" section in the yaml file [link](./helm-values.yaml#L13)
```
helm install cilium isovalent/cilium --version 1.16.8  --namespace kube-system -f  helm-values.yaml 
```

3. Check helm values and that all Cilium agent pods are up
```
helm get values cilium -n kube-system
kubectl get pods -n kube-system
```

4. Apply Cilium egress gateway policy yaml
```
kubectl apply -f 10-egw.yaml
```

5. Verify EGW:
```
kubectl edit IsovalentEgressGatewayPolicy egress-green
```

I scroll down and look for something like this:
```
status:
  conditions:
  - lastTransitionTime: "2025-04-23T03:36:05Z"
    message: allocation requests satisfied
    observedGeneration: 1
    reason: noreason
    status: "True"
    type: isovalent.com/IPAMRequestSatisfied
  groupStatuses:
  - activeGatewayIPs:
    - 10.10.11.2
    egressIPByGatewayIP:
      10.10.11.2: 192.150.9.124       <-----------------
    healthyGatewayIPs:
    - 10.10.11.2
  observedGeneration: 1
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
kubectl apply -f 20-bgp-cluster.yaml 
```

8. Apply BGP peer config:
```
kubectl apply -f 30-bgp-peer.yaml 
```

9. Apply BGP advertisement
```
kubectl apply -f 40-bgp-advert.yaml 
```

10. Verify BGP peer session established and Cilium is advertising the VIP route:
```
cilium bgp peers
cilium bgp routes
```

Example output:
```
cisco@k8s-cp:~/cilium-egw/cilium-cisco-lab$ cilium bgp peers
Node      Local AS   Peer AS   Peer Address   Session State   Uptime   Family         Received   Advertised
k8s-egw   65010      65005     10.0.0.5       established     16m16s   ipv4/unicast   2          1    
cisco@k8s-cp:~/cilium-egw/cilium-cisco-lab$ cilium bgp routes
(Defaulting to `available ipv4 unicast` routes, please see help for more options)

Node      VRouter   Prefix             NextHop   Age      Attrs
k8s-egw   65010     192.150.9.124/32   0.0.0.0   16m25s   [{Origin: i} {Nexthop: 0.0.0.0}]   
```

11. Test connectivity to DCI/Internet - for this I exec into one of my 'blue' namespace pods and simply ping the DCI:
```
kubectl exec -it -n blue bluepod0 -- ping 10.0.0.5
```

12. Verify outbound NAT/PAT - I run a tcpdump on the egress gateway worker node 'ens224' equivalent:
```
tcpdump -ni ens224
```

Example:
```
cisco@k8s-egw:~$ sudo tcpdump -ni ens5
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:57:01.938024 IP 192.150.9.124 > 10.0.0.5: ICMP echo request, id 39110, seq 7, length 64
20:57:01.947628 IP 10.0.0.5 > 192.150.9.124: ICMP echo reply, id 39110, seq 7, length 64
20:57:02.239077 IP 192.150.9.124 > 10.0.0.5: ICMP echo request, id 39110, seq 8, length 64
20:57:02.247122 IP 10.0.0.5 > 192.150.9.124: ICMP echo reply, id 39110, seq 8, length 64
```