## chicken-egg procedure for bootstrapping the Green gateway

1. Green gateway nodes are active and dual homed with default route set to 'node network'
   
Example green1:
```yaml
network:
  ethernets:
    ens4:
      addresses:
        - 10.10.10.103/24
        - fc00:0:1000::103/64
      nameservers:
        addresses: [8.8.8.8]
      routes: 
        - to: default           <--------
          via: 10.10.10.3       <--------
        # - to: 10.0.0.0/8
        #   via: 10.10.10.1
    ens5:
      addresses:
        - 10.10.21.2/24
    #   routes:
    #     - to: default
    #       via: 10.10.21.1
  version: 2
```

2. Install all Internet-dependent packages, example
```yaml
cisco@k8s-egw-green1:~$ sudo apt update
Hit:1 http://us.archive.ubuntu.com/ubuntu jammy InRelease
Get:2 http://us.archive.ubuntu.com/ubuntu jammy-updates InRelease [128 kB]
Get:3 http://us.archive.ubuntu.com/ubuntu jammy-backports InRelease [127 kB]
Get:4 http://us.archive.ubuntu.com/ubuntu jammy-security InRelease [129 kB]
Hit:5 https://prod-cdn.packages.k8s.io/repositories/isv:/kubernetes:/core:/stable:/v1.31/deb  InRelease
Fetched 384 kB in 6s (69.4 kB/s)
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
20 packages can be upgraded. Run 'apt list --upgradable' to see them.
```

3. Join K8s cluster
On CP
```
kubeadm token create --print-join-command
```
```
cisco@k8s-cp:~/cilium-egw/vm-config$ kubectl get nodes -o wide
NAME             STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-cp           Ready    control-plane   23m     v1.31.8   10.10.10.2     <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
k8s-egw-blue1    Ready    <none>          2m57s   v1.31.8   10.10.10.101   <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
k8s-egw-blue2    Ready    <none>          2m17s   v1.31.8   10.10.10.102   <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
k8s-egw-green1   Ready    <none>          72s     v1.31.8   10.10.10.103   <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
k8s-egw-green2   Ready    <none>          10s     v1.31.8   10.10.10.104   <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
k8s-wkr0         Ready    <none>          7m22s   v1.31.8   10.10.10.105   <none>        Ubuntu 22.04.5 LTS   5.15.0-142-generic   containerd://1.7.27
```

4. Install Cilium from Helm chart
```
helm install cilium isovalent/cilium --namespace kube-system -f  helm-values-LB.yaml
```
Verify
```
kubectl get pods -n kube-system
```

5. Label GW nodes
```
kubectl label node k8s-egw-blue1 egressnode=blue
kubectl label node k8s-egw-blue2 egressnode=blue

kubectl label node k8s-egw-green1 egressnode=green
kubectl label node k8s-egw-green2 egressnode=green
```

6. Final package update if needed
```
sudo apt update
sudo crictl pull <image>
```

7. Flip default route on EGW Green nodes
```yaml
    ens4:
      addresses:
        - 10.10.10.103/24
        - fc00:0:1000::103/64
      nameservers:
        addresses: [8.8.8.8]
      routes:
        #- to: default
        #  via: 10.10.10.3
        - to: 10.10.0.0/20
          via: 10.10.10.1
    ens5:
      addresses:
        - 10.10.21.2/24
      routes:
        - to: default
          via: 10.10.21.1
```
```
sudo netplan apply
```

8. apply green GW config
```
kubectl apply -f 10-egw-green-HA.yaml
kubectl apply -f 20-bgp-cluster-green.yaml 
kubectl apply -f 30-bgp-peer-green.yaml
kubectl apply -f 40-bgp-advert-green.yaml 
```

