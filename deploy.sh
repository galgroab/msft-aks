#!/usr/bin/env bash

# Cluster bootstrap
echo "[INFO][deploy.sh] Creating k8s cluster..."
rm -rf _output/
aks-engine deploy  \
    --resource-group btc-info \
    --location westus2 \
    --api-model kubernetes.json

echo "[INFO][deploy.sh] Sleeping 60s for cluster stabilization..."
sleep 60
# update kubeconfig
echo "[INFO][deploy.sh] Updating Kubeconfig..."
export KUBECONFIG=_output/btc-info/kubeconfig/kubeconfig.westus2.json


#install nginx-ingress-controller
echo "[INFO][deploy.sh] Installing Nginx ingress controller..."
helm repo add nginx-stable https://helm.nginx.com/stable > /dev/null 2>&1
helm repo update > /dev/null 2>&1
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace default \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
echo "[INFO][deploy.sh] Waiting for Ingress init..."
echo "[INFO][deploy.sh] Checking Cluster connection"...

while ! nc -z btc-info.westus2.cloudapp.azure.com 443; do   
  echo "[WARN][deploy.sh] Waiting Cluster to listen on 443..."
  sleep 5
done
echo "[INFO][deploy.sh] Success!"

echo "[INFO][deploy.sh] Waiting for Ingress init..."
export KUBECONFIG=_output/btc-info/kubeconfig/kubeconfig.westus2.json
sleep 60

external_ip=""
while [ -z $external_ip ]; do
  export KUBECONFIG=_output/btc-info/kubeconfig/kubeconfig.westus2.json
  "[INFO][deploy.sh] Waiting for Ingress external IP..."
  while ! nc -z btc-info.westus2.cloudapp.azure.com 443; do   
    echo "[WARN][deploy.sh] Waiting Cluster to listen on 443..."
    sleep 5
  done
  echo "[INFO][deploy.sh] Success!"
  external_ip=$(kubectl get svc ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}') 
 sleep 10
done

echo 'End point ready:' && echo $external_ip

# running kustomize to deploy services
echo "[INFO][deploy.sh] Running kusomize to deploy all services..."
cd app/
export KUBECONFIG=../_output/btc-info/kubeconfig/kubeconfig.westus2.json
kustomize build | kubectl apply -f -

echo "[INFO][deploy.sh] Use the LB to access the /btc or /v1/myapp services"
lb=$(kubectl get svc ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "[INFO][deploy.sh] Waiting for services to finish boot..."
sleep 60
# Can use  kubectl wait --for=condition=Available=True deploy/myapp
echo "[INFO][deploy.sh] LB IP: $lb"
echo "[INFO][deploy.sh] BTC Service: http://$lb/btc"
echo "[INFO][deploy.sh] REST Service: http://$lb/v1/myapp"
echo "[INFO][deploy.sh] ######### DONE #########"
