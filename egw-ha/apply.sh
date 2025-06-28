#! /bin/bash

kubectl apply -f 12-egw-blue-HA.yaml
kubectl apply -f 21-bgp-cluster-blue.yaml
kubectl apply -f 31-bgp-peer-blue.yaml
kubectl apply -f 41-bgp-advert-blue.yaml