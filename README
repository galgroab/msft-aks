#!/usr/bin/env bash

# Cluster bootstrap

echo "[INFO][deploy.sh] Creating k8s cluster..."
rm -rf _output/
aks-engine deploy  \
    --resource-group btc-info \
    --location westus2 \
    --api-model kubernetes.json

# update kubeconfig

echo "[INFO][deploy.sh] updating kubeconfig..."
export KUBECONFIG=_output/btc-info/kubeconfig/kubeconfig.westus2.json


#install nginx-ingress-controller

echo "[INFO][deploy.sh] Installing Nginx ingress controller..."
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace default \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
sleep 10

# running kustomize to deploy services
echo "[INFO][deploy.sh] Running kusomize to deploy all services..."
cd app/
export KUBECONFIG=../_output/btc-info/kubeconfig/kubeconfig.westus2.json
kustomize build | kubectl apply -f -




echo "[INFO][deploy.sh] Use the LB to access to seprvice /btc or /v1/myapp"
lb=$(kubectl get ingress btc-ingress --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "[INFO][deploy.sh] ####### DONE #######"
echo "[INFO][deploy.sh] LB IP: $lb"
echo "[INFO][deploy.sh] BTC Service: http://$lb/btc"
echo "[INFO][deploy.sh] REST Service: http://$lb/v1/myapp"
