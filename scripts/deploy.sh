#!/bin/bash

echo "Create WordPress"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep deployed | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of wordpress if it exists"
kubectl delete --ignore-not-found=true -f local-volumes.yaml
kubectl delete --ignore-not-found=true secret mysql-pass
kubectl delete --ignore-not-found=true -f mysql-deployment.yaml
kubectl delete --ignore-not-found=true -f wordpress-deployment.yaml

echo -e "Creating pods"
echo 'password' > password.txt
tr -d '\n' <password.txt >.strippedpassword.txt && mv .strippedpassword.txt password.txt
kubectl create -f local-volumes.yaml
kubectl create secret generic mysql-pass --from-file=password.txt
kubectl create -f mysql-deployment.yaml
kubectl create -f wordpress-deployment.yaml
kubectl scale deployments/wordpress --replicas=2

PORT=$(kubectl get service wordpress | grep wordpress | sed 's/.*://g' | sed 's/\/.*//g')

echo ""
echo "View the wordpress at http://$IP_ADDR:$PORT"
