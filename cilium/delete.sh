#!/bin/bash

kubectl delete -f 01-egw-policy.yaml
kubectl delete -f 10-bgp-cluster.yaml
kubectl delete -f 11-bgp-peer.yaml
kubectl delete -f 12-bgp-advert.yaml

