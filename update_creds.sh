#!/bin/bash -e
# AWS_ACCOUNT, AWS_REGION, K8S_SECRET_NAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY are
# provided through environment varaibles
DOCKER_REGISTRY_SERVER=https://${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
DOCKER_USER=AWS
DOCKER_PASSWORD=`aws ecr get-login --region ${AWS_REGION} --registry-ids ${AWS_ACCOUNT} | cut -d' ' -f6`

kubectl delete secret ${K8S_SECRET_NAME} || true

kubectl create secret docker-registry ${K8S_SECRET_NAME} \
	--docker-server=$DOCKER_REGISTRY_SERVER \
	--docker-username=$DOCKER_USER \
	--docker-password=$DOCKER_PASSWORD \
	--docker-email=no@email.local

kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"'${K8S_SECRET_NAME}'"}]}'
