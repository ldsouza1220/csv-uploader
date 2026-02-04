# Architecture Decision Records

This directory contains ADRs documenting key technical decisions.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-development-environment.md) | Development Environment Strategy | Accepted |
| [0002](0002-sqlite-demo.md) | SQLite for Demo | Accepted |
| [0003](0003-aws-infrastructure.md) | AWS Infrastructure (EKS + VPC) | Accepted |
| [0004](0004-flux-gitops.md) | Flux CD for GitOps | Accepted |
| [0005](0005-gateway-api.md) | Gateway API with NGINX Gateway Fabric | Accepted |
| [0006](0006-karpenter.md) | Karpenter for Node Scaling | Accepted |
| [0007](0007-terraform-local-state.md) | Terraform Local State | Accepted |
| [0008](0008-ci-cd-pipeline.md) | CI/CD Pipeline | Accepted |
| [0009](0009-security.md) | Security Practices | Accepted |

## Format

Each ADR follows:

```markdown
# ADR-XXXX: Title

**Status:** Accepted | Superseded | Deprecated

## Context
Why we needed to decide

## Decision
What we decided

## Consequences
Pros and cons
```
