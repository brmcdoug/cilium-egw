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
