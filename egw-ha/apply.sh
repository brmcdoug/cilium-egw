#! /bin/bash

kubectl apply -f 10-egw-green-HA.yaml
kubectl apply -f 11-egw-blue-HA.yaml
kubectl apply -f 20-bgp-cluster-green.yaml
kubectl apply -f 21-bgp-cluster-blue.yaml
kubectl apply -f 30-bgp-peer-green.yaml
kubectl apply -f 31-bgp-peer-blue.yaml
kubectl apply -f 40-bgp-advert-green.yaml
kubectl apply -f 41-bgp-advert-blue.yaml