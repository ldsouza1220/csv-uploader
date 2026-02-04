# ADR-0006: Karpenter for Node Scaling

**Status:** Accepted

## Context

Production needs dynamic node scaling. Cluster Autoscaler works but has limitations:
- Slow (minutes to provision)
- Requires pre-defined ASG configurations
- Limited instance flexibility

## Decision

Use Karpenter v1.8.2 for node autoscaling.

Karpenter provisions EC2 instances directly via Fleet API - no ASGs, faster scaling.

Configuration:
- **NodePool**: Scheduling constraints
- **EC2NodeClass**: AMI, security groups, instance config
- **Spot preferred**: On-demand as fallback
- **Consolidation enabled**: Bin-packs workloads to reduce costs

Instance selection:
```yaml
requirements:
  - key: karpenter.sh/capacity-type
    operator: In
    values: ["spot", "on-demand"]
  - key: karpenter.k8s.aws/instance-category
    operator: In
    values: ["c", "m", "r"]
```

## Consequences

**Pros:**
- Node provisioning < 60 seconds
- Automatic instance type selection
- Cost optimization via Spot + consolidation

**Cons:**
- AWS-specific (EC2NodeClass not portable)
- Requires IAM roles for controller and nodes
- More complex debugging than static node groups
