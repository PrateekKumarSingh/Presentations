# Tutorial: Docker + Kubernetes Quickstart

This guide is optimized for macOS with Docker Desktop and minikube.

## 0) Setup and Context

### Definition

A Kubernetes context is a tuple of cluster, user, and namespace used by kubectl.

### Commands

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics
bash scripts/00-prereq-check.sh
bash scripts/01-start-minikube.sh
kubectl get nodes
```

## 1) Image (Docker)

### Definition

An image is a read-only package containing app code, runtime, and dependencies.

### Files

- `lab/app/Dockerfile`
- `lab/app/index.html`

### Commands

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics/lab/app

docker build -t hello-web:1.0 .
docker run --rm -p 8081:80 hello-web:1.0
# open http://localhost:8081

minikube image load hello-web:1.0
```

## 2) Pod

### Definition

A Pod is the smallest deployable unit in Kubernetes and usually contains one app container.

### Manifest File

- `lab/manifests/01-pod.yaml`

### Commands
    
```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics
kubectl apply -f lab/manifests/01-pod.yaml
kubectl get pod hello-pod -o wide
kubectl port-forward pod/hello-pod 8082:80
# open http://localhost:8082
```

Optional cleanup:

```bash
kubectl delete pod hello-pod
```

## 3) Deployment + Labels + Selectors (10-14 min)

### Definitions

- Deployment: Controller that keeps N replicas running and supports rolling updates.
- Label: Key-value metadata on objects, like app=hello.
- Selector: Query used to match objects by label.

### Manifest File

- `lab/manifests/02-deployment.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/02-deployment.yaml
kubectl get deploy,pods
kubectl get pods -l app=hello

kubectl scale deployment hello-deploy --replicas=3
kubectl get pods -l app=hello
```

## 4) Service (14-17 min)

### Definition

A Service is a stable endpoint in front of a changing set of Pods.

### Manifest File

- `lab/manifests/03-service.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/03-service.yaml
kubectl get svc hello-svc
minikube service hello-svc
```

## 5) Ingress (17-20 min)

### Definition

Ingress routes HTTP/HTTPS traffic by host/path to Services.

### Manifest File

- `lab/manifests/04-ingress.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/04-ingress.yaml
kubectl get ingress hello-ing

MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP hello.local" | sudo tee -a /etc/hosts
curl -H "Host: hello.local" "http://$MINIKUBE_IP/"
```

## 6) ConfigMap (20-21 min)

### Definition

ConfigMap stores non-secret configuration and can be injected as env vars or files.

### Manifest Files

- `lab/manifests/05-configmap.yaml`
- `lab/manifests/06-cm-pod.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/05-configmap.yaml
kubectl apply -f lab/manifests/06-cm-pod.yaml
kubectl logs cm-demo
kubectl delete pod cm-demo
```

## 7) Secret (21-23 min)

### Definition

Secret stores sensitive values and exposes them to Pods securely via env vars or mounted files.

### Manifest Files

- `lab/manifests/07-secret.yaml`
- `lab/manifests/08-secret-pod.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/07-secret.yaml
kubectl apply -f lab/manifests/08-secret-pod.yaml
kubectl logs secret-demo
kubectl delete pod secret-demo
```

## 8) Requests and Limits (23-24 min)

### Definitions

- Requests: Minimum CPU/memory needed for scheduling.
- Limits: Maximum CPU/memory a container can consume.

### Manifest File

- `lab/manifests/09-resources-pod.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/09-resources-pod.yaml
kubectl describe pod resources-demo | sed -n '/Requests:/,/QoS Class:/p'
kubectl delete pod resources-demo
```

## 9) Probes (24-26 min)

### Definitions

- Readiness probe: Determines if Pod is ready for traffic.
- Liveness probe: Determines if container should be restarted.

### Manifest File

- `lab/manifests/10-probes-deployment.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/10-probes-deployment.yaml
kubectl get pods -l app=probes
kubectl delete deployment probes-demo
```

## 10) Namespace (26-27 min)

### Definition

A Namespace is a logical boundary for environments or teams.

### Manifest File

- `lab/manifests/11-namespace.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/11-namespace.yaml
kubectl -n demo apply -f lab/manifests/02-deployment.yaml
kubectl -n demo get all
kubectl delete namespace demo
```

## 11) PVC / Storage (27-28 min)

### Definition

A PVC is a request for persistent storage and may dynamically provision a PV.

### Manifest Files

- `lab/manifests/12-pvc.yaml`
- `lab/manifests/13-pvc-pod.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/12-pvc.yaml
kubectl apply -f lab/manifests/13-pvc-pod.yaml
kubectl logs pvc-demo
kubectl delete pod pvc-demo
kubectl delete pvc demo-pvc
```

## 12) HPA (28-29 min)

### Definition

HPA automatically adjusts replicas based on observed metrics.

### Manifest File

- `lab/manifests/14-hpa.yaml`

### Commands

```bash
kubectl apply -f lab/manifests/14-hpa.yaml
kubectl get hpa

kubectl run -it --rm loadgen --image=busybox:1.36 -- sh -c \
"while true; do wget -q -O- http://hello-svc; done"

kubectl get hpa -w
```

Cleanup HPA:

```bash
kubectl delete hpa hello-deploy
```

## 13) Debugging Toolkit (29-30 min)

### Definitions

- logs: stdout/stderr from containers
- exec: run commands inside containers
- describe: detailed object state and events

### Commands

```bash
kubectl get pods
kubectl logs deploy/hello-deploy
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod-name>
kubectl exec -it <pod-name> -- sh
```

## One-Shot Cleanup

```bash
bash /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics/scripts/99-cleanup.sh
```
