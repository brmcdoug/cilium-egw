#! /bin/bash

kubectl delete -f 12-egw-blue-HA.yaml
kubectl delete -f 21-bgp-cluster-blue.yaml
kubectl delete -f 31-bgp-peer-blue.yaml
kubectl delete -f 41-bgp-advert-blue.yaml