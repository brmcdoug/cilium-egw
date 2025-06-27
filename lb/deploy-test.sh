#!/bin/bash

echo "Deploying nginx test deployment..."
kubectl apply -f nginx-test-dp.yaml

echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/my-nginx

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