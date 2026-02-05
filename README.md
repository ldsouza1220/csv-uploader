# DevOps Challenge

A multi-application Kubernetes deployment showcasing modern DevOps practices with GitOps, infrastructure as code, and cloud-native patterns.

## Applications

This repository contains **two applications**:

| Application | Description |
|-------------|-------------|
| **csv-uploader** | A FastAPI web application that receives CSV files and stores them in S3-compatible object storage (MinIO for development, AWS S3 for production) |
| **panda-secret** | A lightweight demo application serving a static website with an embedded Kubernetes secret |

## Repository Structure

```
/
├── apps/
│   └── csv-uploader/           # FastAPI application source code
│       ├── main.py             # Application entry point
│       ├── tests/              # Pytest test suite
│       └── docker-compose.yml  # Local development setup
│
├── infra/
│   ├── helm/                   # Helm charts for both applications
│   │   ├── csv-uploader/
│   │   └── panda-secret/
│   │
│   ├── dev/                    # Development environment (Minikube + Helm)
│   │   └── k8s/                # Makefile + Helm values
│   │
│   └── prod/                   # Production environment (AWS EKS)
│       ├── terraform/          # EKS cluster, VPC, S3 bucket
│       └── k8s/                # Flux CD GitOps manifests
│           ├── flux/           # Infrastructure components
│           ├── flux-apps/      # Application deployments
│           └── flux-configs/   # Cluster configurations
│
├── k6/                         # Load testing scripts
├── docs/adr/                   # Architecture Decision Records
└── .github/workflows/          # CI/CD pipelines
```

## Environments

| Environment | Kubernetes | Object Storage | Ingress | Setup |
|-------------|------------|----------------|---------|-------|
| **Local** | Docker Compose | MinIO | localhost:8000 | `docker-compose up` |
| **Dev** | Minikube + Helm | MinIO | Ingress | `make all` |
| **Prod** | AWS EKS + Flux CD | AWS S3 | Gateway API + NLB | Terraform + GitOps |

## GitOps with Flux CD (Production)

Production uses [Flux CD](https://fluxcd.io/) for GitOps-based deployments:

- cert-manager (TLS certificates via Let's Encrypt)
- external-dns (Cloudflare DNS management)
- nginx-gateway-fabric (Gateway API implementation)
- karpenter (Node auto-scaling)
- Application deployments (csv-uploader, panda-secret)

Dev environment uses plain Helm + Makefile for simplicity (KISS principle). See [ADR-0001](docs/adr/0001-development-environment.md).

## Getting Started

### Try It Locally

The fastest way to test the csv-uploader application:

```bash
cd apps/csv-uploader
docker-compose up --build

# App: http://localhost:8000
# MinIO Console: http://localhost:9001 (minioadmin/minioadmin)
```

## Development Environment (Minikube + Helm)

```bash
cd infra/dev/k8s
make all
```

Add hosts and start ingress:

```bash
echo '127.0.0.1 csv.local pandas.local minio.local' | sudo tee -a /etc/hosts
make tunnel
```

Access apps:
- http://csv.local - CSV Uploader
- http://pandas.local - Panda Secret
- http://minio.local - MinIO Console (minioadmin/minioadmin123)

See [infra/dev/k8s/README.md](infra/dev/k8s/README.md) for detailed documentation.

## Production Environment (AWS EKS)

The production infrastructure is managed with Terraform:

```bash
cd infra/prod/terraform
terraform init
terraform apply
```

See [infra/prod/terraform/README.md](infra/prod/terraform/README.md) for more Terraform details.

This provisions:
- EKS cluster with Karpenter for node auto-scaling
- Multi-AZ VPC with public/private subnet separation
- S3 bucket with versioning and lifecycle policies
- IAM roles for service accounts (IRSA)

See [infra/prod/k8s/README.md](infra/prod/k8s/README.md) for Kubernetes deployment details.

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/csv-uploader.yml`) implements:

1. **Lint** - Code quality checks with ruff
2. **Test** - Pytest with mocked S3
3. **Build** - Docker image pushed to GHCR
4. **Deploy** - GitOps update to trigger Flux reconciliation


## Architecture Decision Records

Review the [Architecture Decision Records](docs/adr/README.md) to understand key technical decisions:

| ADR | Decision |
|-----|----------|
| [0001](docs/adr/0001-development-environment.md) | Development Environment Strategy |
| [0002](docs/adr/0002-sqlite-demo.md) | SQLite for Demo |
| [0003](docs/adr/0003-aws-infrastructure.md) | AWS Infrastructure (EKS + VPC) |
| [0004](docs/adr/0004-flux-gitops.md) | Flux CD for GitOps |
| [0005](docs/adr/0005-gateway-api.md) | Gateway API |
| [0006](docs/adr/0006-karpenter.md) | Karpenter for Node Scaling |
| [0007](docs/adr/0007-terraform-local-state.md) | Terraform Local State |
| [0008](docs/adr/0008-ci-cd-pipeline.md) | CI/CD Pipeline |
| [0009](docs/adr/0009-security.md) | Security Practices |
