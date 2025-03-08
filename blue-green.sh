#!/bin/bash

echo "Initializing Green Environment"
kubectl apply -f starter/apps/blue-green/green.yml 
kubectl apply -f starter/apps/blue-green/index_green_html.yml

echo "Green deployment created successfully"