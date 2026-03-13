# 30-Minute Docker + Kubernetes Walkthrough (macOS + Docker Desktop + minikube)

This is a full beginner-friendly, command-first tutorial with core definitions and working manifests.

## What You Will Learn

- Docker image basics
- Kubernetes core concepts: Pod, Deployment, Service, Ingress
- ConfigMap and Secret
- Requests and Limits
- Readiness and Liveness probes
- Namespace isolation
- Persistent storage (PVC)
- Horizontal Pod Autoscaling (HPA)
- Debugging with logs, exec, describe, and events

## Lab Files

- App: `lab/app`
- Kubernetes manifests: `lab/manifests`
- Scripts: `scripts`
- Alternate full guide: `tutorial-30-min.md`

## 0) Setup and Context (0-3 min)

Definition:
A kube context is a combination of cluster, user, and namespace used by kubectl.

Run:

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics
bash scripts/00-prereq-check.sh
bash scripts/01-start-minikube.sh
kubectl get nodes
```

## 1) Docker Image (3-7 min)

Definition:
An image is a read-only package containing your app and dependencies.

Files used:

- `lab/app/index.html`
- `lab/app/Dockerfile`

Run:

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics/lab/app
docker build -t hello-web:1.0 .
docker run --rm -p 8081:80 hello-web:1.0
# open http://localhost:8081

minikube image load hello-web:1.0
```

## 2) Pod (7-10 min)

Definition:
Pod is the smallest deployable unit in Kubernetes.

Manifest:

- `lab/manifests/01-pod.yaml`

Run:

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics
kubectl apply -f lab/manifests/01-pod.yaml
kubectl get pod hello-pod -o wide
kubectl port-forward pod/hello-pod 8082:80
# open http://localhost:8082
```

## 3) Deployment + Labels + Selectors (10-14 min)

Definitions:

- Deployment: Keeps desired replicas running and supports rolling updates.
- Label: Metadata such as app=hello.
- Selector: Query to match labels.

Manifest:

- `lab/manifests/02-deployment.yaml`

Run:

```bash
kubectl apply -f lab/manifests/02-deployment.yaml
kubectl get deploy,pods
kubectl get pods -l app=hello

kubectl scale deployment hello-deploy --replicas=3
kubectl get pods -l app=hello
```

## 4) Service (14-17 min)

Definition:
Service is a stable endpoint in front of dynamic Pods.

Manifest:

- `lab/manifests/03-service.yaml`

Run:

```bash
kubectl apply -f lab/manifests/03-service.yaml
kubectl get svc hello-svc
minikube service hello-svc
```

## 5) Ingress (17-20 min)

Definition:
Ingress routes HTTP/HTTPS traffic by host/path to Services.

Manifest:

- `lab/manifests/04-ingress.yaml`

Run:

```bash
kubectl apply -f lab/manifests/04-ingress.yaml
kubectl get ingress hello-ing

MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP hello.local" | sudo tee -a /etc/hosts
curl -H "Host: hello.local" "http://$MINIKUBE_IP/"
```

## 6) ConfigMap (20-21 min)

Definition:
ConfigMap stores non-secret configuration values.

Manifests:

- `lab/manifests/05-configmap.yaml`
- `lab/manifests/06-cm-pod.yaml`

Run:

```bash
kubectl apply -f lab/manifests/05-configmap.yaml
kubectl apply -f lab/manifests/06-cm-pod.yaml
kubectl logs cm-demo
kubectl delete pod cm-demo
```

## 7) Secret (21-23 min)

Definition:
Secret stores sensitive values such as tokens and passwords.

Manifests:

- `lab/manifests/07-secret.yaml`
- `lab/manifests/08-secret-pod.yaml`

Run:

```bash
kubectl apply -f lab/manifests/07-secret.yaml
kubectl apply -f lab/manifests/08-secret-pod.yaml
kubectl logs secret-demo
kubectl delete pod secret-demo
```

## 8) Requests and Limits (23-24 min)

Definitions:

- Requests: minimum resources for scheduling.
- Limits: maximum resources container can consume.

Manifest:

- `lab/manifests/09-resources-pod.yaml`

Run:

```bash
kubectl apply -f lab/manifests/09-resources-pod.yaml
kubectl describe pod resources-demo | sed -n '/Requests:/,/QoS Class:/p'
kubectl delete pod resources-demo
```

## 9) Probes (24-26 min)

Definitions:

- Readiness probe: whether Pod should receive traffic.
- Liveness probe: whether container should be restarted.

Manifest:

- `lab/manifests/10-probes-deployment.yaml`

Run:

```bash
kubectl apply -f lab/manifests/10-probes-deployment.yaml
kubectl get pods -l app=probes
kubectl delete deployment probes-demo
```

## 10) Namespace (26-27 min)

Definition:
Namespace is a logical isolation boundary.

Manifest:

- `lab/manifests/11-namespace.yaml`

Run:

```bash
kubectl apply -f lab/manifests/11-namespace.yaml
kubectl -n demo apply -f lab/manifests/02-deployment.yaml
kubectl -n demo get all
kubectl delete namespace demo
```

## 11) PVC / Storage (27-28 min)

Definition:
PVC (PersistentVolumeClaim) requests persistent storage.

Manifests:

- `lab/manifests/12-pvc.yaml`
- `lab/manifests/13-pvc-pod.yaml`

Run:

```bash
kubectl apply -f lab/manifests/12-pvc.yaml
kubectl apply -f lab/manifests/13-pvc-pod.yaml
kubectl logs pvc-demo
kubectl delete pod pvc-demo
kubectl delete pvc demo-pvc
```

## 12) HPA (28-29 min)

Definition:
HPA (Horizontal Pod Autoscaler) changes replica count based on metrics.

Manifest:

- `lab/manifests/14-hpa.yaml`

Run:

```bash
kubectl apply -f lab/manifests/14-hpa.yaml
kubectl get hpa

kubectl run -it --rm loadgen --image=busybox:1.36 -- sh -c \
"while true; do wget -q -O- http://hello-svc; done"

kubectl get hpa -w
```

Stop HPA test:

```bash
kubectl delete hpa hello-deploy
```

## 13) Debugging Toolkit (29-30 min)

Definitions:

- logs: application stdout/stderr
- exec: run command inside a container
- describe/events: reason for scheduling or runtime issues

Run:

```bash
kubectl get pods
kubectl logs deploy/hello-deploy
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- sh
```

## One-shot Cleanup

```bash
bash /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics/scripts/99-cleanup.sh
```
