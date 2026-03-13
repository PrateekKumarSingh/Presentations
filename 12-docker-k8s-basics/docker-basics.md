# Docker Basics (Quick Primer)

## Core Concepts

| Term | Definition |
|------|-----------|
| **Image** | A read-only, layered package of your app code, runtime, and dependencies. |
| **Container** | A running, isolated instance of an image with its own filesystem and network. |
| **Dockerfile** | A text file of instructions that tells Docker how to build an image layer by layer. |
| **Registry** | A remote image store (Docker Hub, GHCR, ACR, etc.) to push/pull images. |
| **Layer** | Each `RUN`, `COPY`, or `ADD` instruction creates a new read-only layer in an image. |
| **Volume** | A persistent storage location mounted into a container, survives container restarts. |
| **Network** | A virtual network Docker creates so containers can communicate with each other. |
| **Context** | The directory Docker sends to the daemon when building; keep it small with `.dockerignore`. |

---

## 1. Build an Image

```bash
cd /Users/prateek/workspace/repo/presentations/12-docker-k8s-basics/lab/app

# Build and tag
docker build -t hello-web:1.0 .

# Build with a specific Dockerfile
docker build -f Dockerfile -t hello-web:1.0 .

# Build without using the cache (fresh build)
docker build --no-cache -t hello-web:1.0 .

# See the image layers and their sizes
docker history hello-web:1.0
```

---

## 2. List and Inspect Images

```bash
# List all local images
docker images

# Filter by name
docker images hello-web

# Show image details (size, layers, env, entrypoint)
docker inspect hello-web:1.0

# Show only the image ID
docker images -q
```

---

## 3. Run Containers

```bash
# Run interactively, remove on exit
docker run --rm -it hello-web:1.0 sh

# inside the container, you can explore the filesystem, environment variables, etc.
# cat /etc/os-release

# Run in the background (detached), map port 8081 → 80
docker run -d -p 8081:80 --name hello-web hello-web:1.0

# Open in browser: http://localhost:8081

# Run with an environment variable
docker run --rm -e APP_ENV=dev hello-web:1.0

# Run with a named volume mounted at /data
docker run --rm -v mydata:/data busybox sh -c "echo hello > /data/test.txt"

# Run with a bind-mount (host directory → container path)
docker run --rm -v $(pwd):/app -w /app node:20-alpine node index.js
```

---

## 4. Manage Running Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Show resource usage (CPU, memory, network, I/O)
docker stats

# Follow log output from a container
docker logs -f hello-web

# Show last 50 lines of logs with timestamps
docker logs --tail 50 --timestamps hello-web

# Run a command inside a running container
docker exec -it hello-web sh

# Copy a file from host into a container
docker cp ./index.html hello-web:/usr/share/nginx/html/index.html

# Stop and remove a container
docker stop hello-web
docker rm hello-web

# Stop and remove in one shot (only safe when stopped)
docker rm -f hello-web
```

---

## 5. Volumes and Networking

```bash
# Create, list, and remove a named volume
docker volume create mydata
docker volume ls
docker volume rm mydata

# List networks
docker network ls

# Create a custom bridge network
docker network create my-net

# Run two containers on the same network (they can reach each other by name)
docker run -d --network my-net --name app1 nginx:alpine
docker run --rm --network my-net busybox wget -qO- http://app1

# Remove the network
docker network rm my-net
```

---

## 6. Registry: Push and Pull

```bash
# Log in to Docker Hub
docker login

# Tag an image for Docker Hub (username/repo:tag)
docker tag hello-web:1.0 yourdockerhubuser/hello-web:1.0

# Push to Docker Hub
docker push yourdockerhubuser/hello-web:1.0

# Pull from Docker Hub
docker pull nginx:alpine

# Pull from GitHub Container Registry
docker pull ghcr.io/owner/image:tag

# Save an image to a tar file (useful for air-gapped environments)
docker save hello-web:1.0 | gzip > hello-web.tar.gz

# Load an image from a tar file
docker load < hello-web.tar.gz
```

---

## 7. Housekeeping

```bash
# Remove a specific image
docker rmi hello-web:1.0

# Remove ALL stopped containers, dangling images, unused networks and build cache
docker system prune

# Aggressive prune — also removes unused images (not just dangling)
docker system prune -a

# Check disk usage by Docker objects
docker system df
```

---

## 8. Dockerfile Reference (common instructions)

```dockerfile
FROM nginx:alpine            # Base image — always the first instruction
WORKDIR /app                 # Set working directory inside the image
COPY src/ .                  # Copy files from build context into image
RUN apk add --no-cache curl  # Execute a command during build (creates a layer)
ENV PORT=8080                # Set a default environment variable
EXPOSE 80                    # Document the port the container listens on (informational)
VOLUME ["/data"]             # Declare a mount point for persistent data
ENTRYPOINT ["nginx"]         # Process that runs when the container starts
CMD ["-g", "daemon off;"]    # Default arguments to ENTRYPOINT (overridable)
```

---

## Quick Reference Card

| Goal | Command |
|------|---------|
| Build image | `docker build -t name:tag .` |
| Run detached | `docker run -d -p host:container name:tag` |
| Shell into running container | `docker exec -it <id> sh` |
| Follow logs | `docker logs -f <id>` |
| List running | `docker ps` |
| Stop + remove | `docker rm -f <id>` |
| Remove image | `docker rmi name:tag` |
| Prune everything | `docker system prune -a` |
