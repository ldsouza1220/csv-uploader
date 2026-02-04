# ADR-0001: Development Environment Strategy

**Status:** Accepted

## Context

Engineers need fast iteration locally while maintaining confidence that code works in Kubernetes.

## Decision

Three-tier environment setup:

| Environment | Stack | Storage | Use Case |
|-------------|-------|---------|----------|
| Local | docker-compose | MinIO | Daily development |
| Dev | Minikube + Flux | MinIO | K8s-specific testing |
| Prod | EKS + Flux | AWS S3 | Production |

The app uses `ENVIRONMENT` variable to switch between MinIO and S3 endpoints.

No cluster autoscaler in dev - Minikube has fixed resources. HPA works for testing pod scaling, but node scaling requires production.

## Consequences

**Pros:**
- Fast local iteration (seconds to restart)
- Same app code runs everywhere
- No cloud costs for development

**Cons:**
- Minikube doesn't replicate EKS perfectly (no IRSA, different networking)
- Two container configs to maintain (docker-compose + Helm)
