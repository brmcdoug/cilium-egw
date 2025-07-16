## repro steps and results

1. Check original EGW policy
```
kubectl get IsovalentEgressGatewayPolicy -oyaml
```

```
cisco@k8s-cp:~$ kubectl get IsovalentEgressGatewayPolicy -oyaml
apiVersion: v1
items:
- apiVersion: isovalent.com/v1
  kind: IsovalentEgressGatewayPolicy
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"isovalent.com/v1","kind":"IsovalentEgressGatewayPolicy","metadata":{"annotations":{},"labels":{"advertise":"bgp-blue"},"name":"egress-blue"},"spec":{"destinationCIDRs":["10.0.0.0/8"],"egressGroups":[{"maxGatewayNodes":2,"nodeSelector":{"matchLabels":{"egressnode":"blue"}}}],"selectors":[{"podSelector":{}}]}}
    creationTimestamp: "2025-06-30T05:42:09Z"
    generation: 2
    labels:
      advertise: bgp-blue
    name: egress-blue
    resourceVersion: "3070829"
    uid: 4ad29768-4c84-43a9-9cff-22670631fdf6
  spec:
    destinationCIDRs:
    - 10.0.0.0/8
    egressGroups:
    - maxGatewayNodes: 2
      nodeSelector:
        matchLabels:
          egressnode: blue
    selectors:
    - podSelector: {}
  status:
    groupStatuses:
    - activeGatewayIPs:
      - 10.10.10.101
      - 10.10.10.102
      healthyGatewayIPs:
      - 10.10.10.101
      - 10.10.10.102
    observedGeneration: 2
- apiVersion: isovalent.com/v1
  kind: IsovalentEgressGatewayPolicy
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"isovalent.com/v1","kind":"IsovalentEgressGatewayPolicy","metadata":{"annotations":{},"labels":{"advertise":"bgp-green"},"name":"egress-green"},"spec":{"destinationCIDRs":["0.0.0.0/0"],"egressCIDRs":["192.150.9.124/31"],"egressGroups":[{"maxGatewayNodes":2,"nodeSelector":{"matchLabels":{"egressnode":"green"}}}],"selectors":[{"podSelector":{}}]}}
    creationTimestamp: "2025-06-30T05:56:38Z"
    generation: 1
    labels:
      advertise: bgp-green
    name: egress-green
    resourceVersion: "3065878"
    uid: 675e4ef7-3d37-4b7b-90a5-c63ce8cd38cf
  spec:
    destinationCIDRs:
    - 0.0.0.0/0
    egressCIDRs:
    - 192.150.9.124/31
    egressGroups:
    - maxGatewayNodes: 2
      nodeSelector:
        matchLabels:
          egressnode: green
    selectors:
    - podSelector: {}
  status:
    conditions:
    - lastTransitionTime: "2025-07-16T03:03:53Z"
      message: allocation requests satisfied
      observedGeneration: 1
      reason: noreason
      status: "True"
      type: isovalent.com/IPAMRequestSatisfied
    groupStatuses:
    - activeGatewayIPs:
      - 10.10.10.103
      - 10.10.10.104
      egressIPByGatewayIP:
        10.10.10.103: 192.150.9.124
        10.10.10.104: 192.150.9.125
      healthyGatewayIPs:
      - 10.10.10.103
      - 10.10.10.104
    observedGeneration: 1
kind: List
metadata:
  resourceVersion: ""
```

2. Deploy test service
```
kubectl apply -f nginx-test.yaml
```

3. Get podCIDR and and serviceCIDR
```
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' 
kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
```

```
cisco@k8s-cp:~$ kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}' 
172.16.0.0/24 172.16.2.0/24 172.16.3.0/24 172.16.4.0/24 172.16.5.0/24 172.16.1.0/24

cisco@k8s-cp:~$ kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
                            "--service-cluster-ip-range=10.96.0.0/16",
```

4. Verify podCIDR and service/NP:
```
kubectl get pods -l app=nginx-test -o wide
kubectl get svc
```

```
cisco@k8s-cp:~/cilium-egw$ kubectl get pods -l app=nginx-test -o wide
NAME                          READY   STATUS    RESTARTS   AGE     IP             NODE             NOMINATED NODE   READINESS GATES
nginx-test-857f558bf9-9kptw   1/1     Running   0          6m21s   172.16.1.11    k8s-egw-blue1    <none>           <none>
nginx-test-857f558bf9-v2j6f   1/1     Running   0          6m21s   172.16.0.245   k8s-egw-green2   <none>           <none>

cisco@k8s-cp:~/cilium-egw$ kubectl get svc
NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes            ClusterIP      10.96.0.1       <none>        443/TCP        15d
nginx-test-nodeport   NodePort       10.96.163.83    <none>        80:30080/TCP   2m47s
```

5. curl test from inside the cluster
```
kubectl run test-pod --image=curlimages/curl -it --rm -- sh
curl http://10.96.163.83
```

```
cisco@k8s-cp:~/cilium-egw$ kubectl run test-pod --image=curlimages/curl -it --rm -- sh

If you don't see a command prompt, try pressing enter.

~ $ curl http://10.96.163.83
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

6. curl test from outside the cluster:
```
curl http://10.10.10.101:30080 
```

```
cisco@k8s-cp:~/cilium-egw/egw-ha$ curl http://10.10.10.101:30080 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

7. Delete EGW green
```
kubectl delete -f 40-bgp-advert-green.yaml 
kubectl delete -f 30-bgp-peer-green.yaml 
kubectl delete -f 20-bgp-cluster-green.yaml 
kubectl delete -f 10-egw-green-HA.yaml 
```

8. update EGW blue with 0.0.0.0/0 destCIDR
```yaml
  destinationCIDRs:
  - "0.0.0.0/0"
  #- "10.0.0.0/8"
```

9. apply
```
kubectl apply -f 11-blue-HA.yaml
```

10. verify EGW policy:
```
kubectl get IsovalentEgressGatewayPolicy -oyaml
```

```
cisco@k8s-cp:~/cilium-egw/egw-ha$ kubectl get IsovalentEgressGatewayPolicy -oyaml
apiVersion: v1
items:
- apiVersion: isovalent.com/v1
  kind: IsovalentEgressGatewayPolicy
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"isovalent.com/v1","kind":"IsovalentEgressGatewayPolicy","metadata":{"annotations":{},"labels":{"advertise":"bgp-blue"},"name":"egress-blue"},"spec":{"destinationCIDRs":["0.0.0.0/0"],"egressGroups":[{"maxGatewayNodes":2,"nodeSelector":{"matchLabels":{"egressnode":"blue"}}}],"selectors":[{"podSelector":{}}]}}
    creationTimestamp: "2025-06-30T05:42:09Z"
    generation: 3
    labels:
      advertise: bgp-blue
    name: egress-blue
    resourceVersion: "3071850"
    uid: 4ad29768-4c84-43a9-9cff-22670631fdf6
  spec:
    destinationCIDRs:
    - 0.0.0.0/0
    egressGroups:
    - maxGatewayNodes: 2
      nodeSelector:
        matchLabels:
          egressnode: blue
    selectors:
    - podSelector: {}
  status:
    groupStatuses:
    - activeGatewayIPs:
      - 10.10.10.101
      - 10.10.10.102
      healthyGatewayIPs:
      - 10.10.10.101
      - 10.10.10.102
    observedGeneration: 3
kind: List
metadata:
  resourceVersion: ""
```

11. ping test pod to pod
```
cisco@k8s-cp:~/cilium-egw/egw-ha$ kubectl exec -it -n testns1 testpod1 -- ping 172.16.5.185
PING 172.16.5.185 (172.16.5.185): 56 data bytes
64 bytes from 172.16.5.185: seq=0 ttl=63 time=3.744 ms
64 bytes from 172.16.5.185: seq=1 ttl=63 time=1.491 ms
64 bytes from 172.16.5.185: seq=2 ttl=63 time=1.669 ms
```

12. curl test from pod in the cluster
```
~ $ curl http://10.96.163.83
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
~ $ 
```

13. DNS test from pod inside the cluster
```
cisco@k8s-cp:~/cilium-egw/egw-ha$ kubectl exec -it test-alpine-777bf49f54-ngncl -- sh
/ # ping www.adobe.com
PING www.adobe.com (184.25.127.146): 56 data bytes
64 bytes from 184.25.127.146: seq=0 ttl=48 time=19.581 ms
64 bytes from 184.25.127.146: seq=1 ttl=48 time=19.044 ms
^C
```