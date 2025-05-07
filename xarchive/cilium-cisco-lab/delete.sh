#!/bin/bash

kubectl delete -f 10-egw-policy.yaml
kubectl delete -f 20-bgp-cluster.yaml
kubectl delete -f 30-bgp-peer.yaml
kubectl delete -f 40-bgp-advert.yaml

