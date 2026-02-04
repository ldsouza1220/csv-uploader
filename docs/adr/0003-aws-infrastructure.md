# ADR-0003: AWS Infrastructure (EKS + VPC)

**Status:** Accepted

## Context

Running Kubernetes in production requires a reliable control plane and proper network isolation.

## Decision

### EKS
Use Amazon EKS as the managed Kubernetes platform:
- AWS manages API server and etcd
- Multi-AZ control plane by default
- OIDC provider enabled for IRSA (IAM Roles for Service Accounts)
- Managed node group for system workloads

### VPC
Multi-AZ architecture with subnet separation:

| Subnet | Contains | Internet Access |
|--------|----------|-----------------|
| Public | NLB, NAT Gateway | Direct |
| Private | Worker nodes, Pods | Via NAT |

Subnet tags for automatic discovery:
```
kubernetes.io/role/elb: 1              # Public
kubernetes.io/role/internal-elb: 1     # Private
karpenter.sh/discovery: {cluster}      # Karpenter
```

## Consequences

**Pros:**
- No control plane operational burden
- Worker nodes not exposed to internet
- HA across multiple AZs
- Native IAM integration

**Cons:**
- Vendor lock-in to AWS
- EKS cost ($0.10/hour per cluster)
- NAT Gateway costs for outbound traffic
