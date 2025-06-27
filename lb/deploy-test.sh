#!/bin/bash

echo "Deploying Enterprise Ingress Load Balancer Test..."

# Label nodes for ingress load balancer (adjust node names as needed)
echo "Labeling nodes for ingress load balancer..."
kubectl label nodes k8s-egw-blue1 ingressnode=blue --overwrite
kubectl label nodes k8s-egw-blue2 ingressnode=blue --overwrite

# Apply IP pool
echo "Applying LoadBalancer IP Pool..."
kubectl apply -f 10-ingress-lb.yaml

# Apply BGP advertisement (uses existing cluster/peer configs)
echo "Applying BGP Advertisement..."
kubectl apply -f 11-bgp-advert-ingress-blue.yaml

# Apply test deployment and service
echo "Applying test nginx deployment and service..."
kubectl apply -f nginx-test-dp.yaml

echo "Waiting for service to get external IP..."
kubectl get svc nginx-test -w

echo "Deploying DSR service..."
kubectl apply -f svc-dsr.yaml

echo "Deploying SNAT service..."
kubectl apply -f svc-snat.yaml

echo "Waiting for services to get external IPs..."
sleep 10

echo "Checking service status..."
kubectl get services -l app=test-app

echo "Checking pod status..."
kubectl get pods -l app=test-app

echo "Test deployment complete!" 