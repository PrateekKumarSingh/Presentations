#!/usr/bin/env bash
set -euo pipefail

for cmd in docker kubectl minikube; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: $cmd"
    exit 1
  fi
done

echo "All prerequisites found: docker, kubectl, minikube"
docker --version
kubectl version --client
minikube version
