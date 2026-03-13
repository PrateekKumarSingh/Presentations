#!/usr/bin/env bash
set -euo pipefail

kubectl delete ingress hello-ing --ignore-not-found
kubectl delete svc hello-svc --ignore-not-found
kubectl delete deploy hello-deploy --ignore-not-found
kubectl delete deploy probes-demo --ignore-not-found
kubectl delete pod hello-pod --ignore-not-found
kubectl delete pod cm-demo --ignore-not-found
kubectl delete pod secret-demo --ignore-not-found
kubectl delete pod resources-demo --ignore-not-found
kubectl delete pod pvc-demo --ignore-not-found
kubectl delete pvc demo-pvc --ignore-not-found
kubectl delete cm app-config --ignore-not-found
kubectl delete secret app-secret --ignore-not-found
kubectl delete hpa hello-deploy --ignore-not-found
kubectl delete namespace demo --ignore-not-found

echo "Cleanup complete."
