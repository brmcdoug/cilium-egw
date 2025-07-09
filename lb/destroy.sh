#!/bin/bash

echo "Deleting green DSR service..."
kubectl delete -f svc-green-dsr.yaml

echo "Deleting blue SNAT service..."
kubectl delete -f svc-blue-snat.yaml

# Apply test deployment and service
echo "Deleting test nginx deployment..."
kubectl delete -f nginx-blue-dp.yaml
kubectl delete -f nginx-green-dp.yaml

# Apply BGP advertisement (uses existing cluster/peer configs)
echo "Deleting BGP Advertisement..."
kubectl delete -f 11-bgp-advert-ingress-blue.yaml
kubectl delete -f 12-bgp-advert-ingress-green.yaml

# Apply IP pool
echo "Deleting LoadBalancer IP Pool..."
kubectl delete -f 01-ingress-lb-blue.yaml
kubectl delete -f 02-ingress-lb-green.yaml






