#!/bin/bash

echo "Deploying Enterprise Ingress Load Balancer Test..."

# Label nodes for ingress load balancer (adjust node names as needed)
echo "Labeling nodes for ingress load balancer..."
kubectl label nodes k8s-egw-blue1 ingressnode=blue --overwrite
kubectl label nodes k8s-egw-blue2 ingressnode=blue --overwrite

kubectl label nodes k8s-egw-green1 ingressnode=green --overwrite
kubectl label nodes k8s-egw-green2 ingressnode=green --overwrite

# Apply IP pool
echo "Applying LoadBalancer IP Pool..."
kubectl apply -f 01-ingress-lb-blue.yaml
kubectl apply -f 02-ingress-lb-green.yaml


# Apply BGP advertisement (uses existing cluster/peer configs)
echo "Applying BGP Advertisement..."
kubectl apply -f 11-bgp-advert-ingress-blue.yaml
kubectl apply -f 12-bgp-advert-ingress-green.yaml

# Apply test deployment and service
echo "Applying test nginx deployment..."
kubectl apply -f nginx-blue-dp.yaml
kubectl apply -f nginx-green-dp.yaml

echo "Deploying green DSR service..."
kubectl apply -f svc-green-dsr.yaml

echo "Deploying blue SNAT service..."
kubectl apply -f svc-blue-snat.yaml

echo "Waiting for services to get external IPs..."
sleep 10

echo "Checking service status..."
kubectl get services

echo "Checking pod status..."
kubectl get pods 

echo "Test deployment complete!" 