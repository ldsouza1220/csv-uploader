# Kubernetes Configuration (Flux CD)

This directory contains everything Flux deploys to the EKS cluster. Terraform bootstraps Flux, then Flux takes over and manages all Kubernetes resources.

## Add-ons

| Add-on | What it does |
|--------|--------------|
| **Karpenter** | Provisions EC2 instances (auto-scaler)|
| **AWS Load Balancer Controller** | Creates NLB for the Gateway |
| **NGINX Gateway Fabric** | Routes traffic using Gateway API |
| **cert-manager** | Issues TLS certificates from Let's Encrypt |
| **external-dns** | Creates DNS records in Cloudflare |
| **metrics-server** | Enables HPA for pod autoscaling |

## Directory Structure

```
k8s/
├── flux/                    # Infrastructure add-ons
│   ├── namespaces.yaml
│   ├── helm-repositories.yaml
│   └── releases/
│       ├── karpenter.yaml
│       ├── aws-load-balancer-controller.yaml
│       ├── nginx-gateway-fabric.yaml
│       ├── cert-manager.yaml
│       ├── external-dns.yaml
│       └── metrics-server.yaml
│
├── flux-configs/            # Post-install configuration
│   ├── gateway.yaml         # Gateway resource for NGINX
│   └── cluster-issuer.yaml  # Let's Encrypt issuer
│
├── flux-karpenter-configs/  # Karpenter node configuration
│   ├── node-pool.yaml
│   └── ec2-node-class.yaml
│
└── flux-apps/               # Application deployments
    ├── csv-uploader.yaml
    └── panda-secret.yaml
```

## How Flux Organizes Deployments

Flux uses four Kustomizations that deploy in order:

```
k8s-addons (flux/)
    │
    ├── k8s-addons-configs (flux-configs/)
    │
    ├── karpenter-configs (flux-karpenter-configs/)
    │
    └── apps (flux-apps/)
```

This ensures add-ons are ready before apps try to use them.

## Variable Substitution

Terraform injects these values into the manifests at deploy time:

| Variable | Example |
|----------|---------|
| `${CLUSTER_NAME}` | `ounass-eks` |
| `${AWS_REGION}` | `me-central-1` |
| `${DOMAIN}` | `example.com` |
| `${KARPENTER_ROLE_ARN}` | IAM role for Karpenter |
| `${AWS_LB_CONTROLLER_ROLE_ARN}` | IAM role for LB Controller |
| `${VPC_ID}` | VPC where cluster runs |

This lets the same manifests work across different clusters.

## Useful Commands

```bash
# Check what Flux is doing
flux get all -A

# Force a sync
flux reconcile kustomization apps -n flux-system

# Check if HelmReleases are healthy
kubectl get helmreleases -A

# View Flux logs
flux logs -f
```

## Adding a New Application

Create a HelmRelease in `flux-apps/`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
  namespace: flux-system
spec:
  targetNamespace: apps
  chart:
    spec:
      chart: ./infra/helm/my-app
      sourceRef:
        kind: GitRepository
        name: csv-uploader
        namespace: flux-system
  values:
    httpRoute:
      enabled: true
      hostname: my-app.${DOMAIN}
```

Commit and push - Flux picks it up automatically.
