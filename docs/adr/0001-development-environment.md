# ADR-0001: Development Environment Strategy

**Status:** Accepted

## Context

Engineers need fast iteration locally while maintaining confidence that code works in Kubernetes.

## Decision

Three-tier environment setup:

| Environment | Stack | Storage | Deployment |
|-------------|-------|---------|------------|
| Local | docker-compose | MinIO | `docker-compose up` |
| Dev | Minikube + Helm | MinIO | `make install` |
| Prod | EKS + Flux | AWS S3 | GitOps |

The app uses `ENVIRONMENT` variable to switch between MinIO and S3 endpoints.

### Dev Environment: KISS Principle

The dev environment uses a **Makefile with plain Helm commands** instead of Flux. This follows the KISS (Keep It Simple, Stupid) principle:

- We want to test how apps deploy in Kubernetes without GitOps complexity
- No need for GitRepository, HelmRelease CRDs, or reconciliation loops
- Simple `make install` / `make upgrade` / `make clean` workflow
- Ingress configured via Minikube addon + `/etc/hosts`

Flux adds value in production (audit trail, drift detection, automated sync), but in dev it's overhead. A Makefile gives us the same outcome with less moving parts.

### No Cluster Autoscaler in Dev

Minikube has fixed resources. HPA works for testing pod scaling, but node scaling requires production (Karpenter).

## Consequences

**Pros:**
- Fast local iteration (seconds to restart)
- Same Helm charts used in dev and prod
- No cloud costs for development
- Simple debugging (no Flux controllers to troubleshoot)

**Cons:**
- Minikube doesn't replicate EKS perfectly (no IRSA, different networking)
- Manual deploys in dev vs automated in prod
