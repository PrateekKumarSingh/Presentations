#!/usr/bin/env bash
set -euo pipefail

minikube start --driver=docker
kubectl config use-context minikube

# Enable common addons used in this tutorial.
minikube addons enable ingress
minikube addons enable metrics-server

kubectl get nodes
