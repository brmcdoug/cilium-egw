## 2nd repro

1. init cluster with pod and svc cidrs:
```
cisco@k8s-cp:~/cilium-egw/lb$ kubectl cluster-info dump | grep -m 1 cluster-cidr
                            "--cluster-cidr=172.16.0.0/16",

cisco@k8s-cp:~/cilium-egw/lb$ kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
                            "--service-cluster-ip-range=192.168.0.0/18",
```

