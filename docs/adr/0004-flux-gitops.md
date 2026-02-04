# ADR-0004: Flux CD for GitOps

**Status:** Accepted

## Context

Deployments should be declarative, versioned, and auditable. GitOps uses Git as the source of truth.

Options considered:
- **Flux CD**: Lightweight, CLI-driven
- **Argo CD**: UI-focused, feature-rich

## Decision

Use Flux CD v2. Git push triggers automatic reconciliation.

Components:
- **GitRepository**: Points to repo via SSH deploy key
- **Kustomization**: Reconciles manifests with variable substitution
- **HelmRelease**: Manages Helm charts

Terraform bootstraps Flux and injects variables (cluster name, IAM roles, region) via `postBuild.substitute`.

## Why Not Argo CD

Argo CD's UI is great for developer self-service, but:
- This project is managed by DevOps engineers comfortable with CLI
- Flux has a lighter footprint
- Native variable substitution in Kustomizations

## Consequences

**Pros:**
- Git history = audit trail
- No manual `kubectl apply` in production
- Automatic drift correction

**Cons:**
- No built-in UI
- Debugging requires understanding Flux controllers
