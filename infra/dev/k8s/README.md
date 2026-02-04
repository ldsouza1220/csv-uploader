# Dev Kubernetes Infrastructure (Flux)

This directory contains Flux CD configurations for the development Kubernetes cluster (Minikube).

## Structure

```
flux/
├── kustomization.yaml      # Main kustomization file
├── namespaces/
│   └── csv-processor.yaml  # Application namespace
├── sources/
│   └── minio-helmrepo.yaml # MinIO Helm repository
└── releases/
    └── minio.yaml          # MinIO HelmRelease
```

## Quick Start (From Scratch)

### 1. Start Minikube

```bash
# Delete existing cluster (if any)
minikube delete

# Start fresh cluster with QEMU driver
minikube start --driver=qemu2

# Or with Docker driver (recommended for tunnel support)
minikube start --driver=docker

# Enable ingress addon
minikube addons enable ingress
```

### 2. Install Flux CLI

```bash
# Option 1: Official install script (recommended)
curl -s https://fluxcd.io/install.sh | bash

# Option 2: Homebrew
brew install fluxcd/tap/flux

# Verify installation
flux --version
```

### 3. Install Flux on Cluster

```bash
# Check prerequisites
flux check --pre

# Install Flux controllers
flux install

# Verify Flux is running
kubectl get pods -n flux-system
```

### 4. Apply Dev Infrastructure

```bash
# Apply all Flux configurations
kubectl apply -k infra/dev/k8s/flux/

# Watch the deployment
flux get helmreleases -n csv-processor -w
```

### 5. Access MinIO

**Option A: Port Forwarding (works with any driver)**
```bash
# Terminal 1 - Console (Web UI)
kubectl port-forward -n csv-processor svc/minio-console 9001:9001

# Terminal 2 - API (S3)
kubectl port-forward -n csv-processor svc/minio 9000:9000
```

**Option B: Minikube Tunnel (requires Docker driver)**
```bash
# Add to /etc/hosts
echo "127.0.0.1 minio.local minio-api.local" | sudo tee -a /etc/hosts

# Start tunnel
minikube tunnel

# Access via ingress hostnames
```

**Access URLs:**
| Service | Port Forward | Ingress |
|---------|--------------|---------|
| Console | http://localhost:9001 | http://minio.local |
| S3 API | http://localhost:9000 | http://minio-api.local |

**Credentials:** `minioadmin` / `minioadmin123`

---

## Common Operations

### Check Flux Status

```bash
# All Flux resources
flux get all -A

# HelmReleases only
flux get helmreleases -n csv-processor

# HelmRepositories
flux get sources helm -A
```

### Force Reconciliation

```bash
# Reconcile HelmRelease
flux reconcile helmrelease minio -n csv-processor

# Reconcile HelmRepository
flux reconcile source helm minio -n flux-system
```

### View Logs

```bash
# Flux controllers
flux logs -f

# MinIO pod
kubectl logs -n csv-processor -l app.kubernetes.io/name=minio -f
```

### Suspend/Resume

```bash
# Suspend (stop reconciliation)
flux suspend helmrelease minio -n csv-processor

# Resume
flux resume helmrelease minio -n csv-processor
```

### Uninstall

```bash
# Remove MinIO HelmRelease
kubectl delete helmrelease minio -n csv-processor

# Remove all Flux configs
kubectl delete -k infra/dev/k8s/flux/

# Uninstall Flux from cluster
flux uninstall

# Delete Minikube cluster
minikube delete
```

---

## Troubleshooting

### Minikube Certificate Expired

```bash
# Delete and recreate
minikube delete
minikube start
```

### HelmRelease Not Ready

```bash
# Check HelmRelease status
flux get helmrelease minio -n csv-processor

# Describe for detailed error
kubectl describe helmrelease minio -n csv-processor

# Check Helm controller logs
kubectl logs -n flux-system deploy/helm-controller
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n csv-processor

# Describe pod for events
kubectl describe pod -n csv-processor -l app.kubernetes.io/name=minio

# Check PVC (storage)
kubectl get pvc -n csv-processor
```

### QEMU Driver Network Issues

The QEMU driver without dedicated network doesn't support `minikube service` or `minikube tunnel`. Use port-forwarding instead, or switch to Docker driver:

```bash
minikube delete
minikube start --driver=docker
```

---

## Components

### MinIO
- **Chart**: minio/minio from https://charts.min.io/
- **Version**: 5.x (latest)
- **Mode**: Standalone (single node)
- **Storage**: 10Gi PVC with `standard` StorageClass
- **Default Bucket**: `test-bucket`
- **Ingress**: nginx (minio.local, minio-api.local)
