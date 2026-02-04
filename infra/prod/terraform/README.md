# Production Infrastructure (AWS EKS)

This Terraform configuration provisions the production EKS cluster and all required AWS resources.

## Architecture

![Architecture Diagram](architecture.png)

## What Gets Created

| Resource | Description |
|----------|-------------|
| EKS Cluster | Kubernetes 1.35 with public API endpoint (not recommended in a real environment) |
| VPC | 3 AZs with public/private subnet separation |
| Managed Node Group | Single t3.xlarge Spot instance for Karpenter controller |
| S3 Bucket | Object storage with versioning and lifecycle policies |
| IAM Roles | IRSA roles for Karpenter, AWS LB Controller, EBS CSI |
| Flux CD | GitOps controller watching this repository |

## Prerequisites

You'll need:
- Terraform >= 1.5
- AWS CLI configured with credentials
- A Cloudflare account with API token (for DNS and TLS)
- A GitHub account (for Flux deploy key)

## Quick Start

### 1. Generate a Flux Deploy Key

Flux needs read access to this repository:

```bash
ssh-keygen -t ed25519 -f flux-deploy-key -N ""
```

Add `flux-deploy-key.pub` as a deploy key in your GitHub repository:
- Go to **Settings > Deploy Keys > Add deploy key**
- Paste the public key content
- Keep it read-only

### 2. Get Your Cloudflare API Token

Create an API token at [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens) with:
- **Zone:DNS:Edit** permission for your domain
- **Zone:Zone:Read** permission

### 3. Configure Variables

Create `terraform.tfvars`:

```hcl
flux_deploy_key_private = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
... your private key ...
-----END OPENSSH PRIVATE KEY-----
EOT

cloudflare_api_token = "your-cloudflare-api-token"

# Optional: use your own domain (default: souzaxx.dev)
domain = "yourdomain.com"
```

Or export as environment variables:

```bash
export TF_VAR_flux_deploy_key_private="$(cat flux-deploy-key)"
export TF_VAR_cloudflare_api_token="your-token"
export TF_VAR_domain="yourdomain.com"
```

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

This takes ~15 minutes. Terraform creates the EKS cluster, then Flux takes over and deploys all the Kubernetes components.

### 5. Connect to the Cluster

```bash
aws eks update-kubeconfig --region me-central-1 --name ounass-eks
kubectl get nodes
```

## Using Your Own Domain

By default, the stack uses `souzaxx.dev`. To use your own domain:

1. Set the `domain` variable in Terraform:
   ```hcl
   domain = "yourdomain.com"
   ```

2. Point your domain's nameservers to Cloudflare (external-dns creates records automatically)

3. After deployment, your apps will be available at:
   - `csv.yourdomain.com` - CSV Uploader
   - `pandas.yourdomain.com` - Panda Secret

The domain variable flows through Flux substitution to all Kubernetes manifests, so you only need to set it once.

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `flux_deploy_key_private` | SSH private key for Flux | (required) |
| `cloudflare_api_token` | Cloudflare API token | (required) |
| `domain` | Base domain for DNS and TLS | `souzaxx.dev` |

## Verification

Check that everything is running:

```bash
# Flux status
flux get all -A

# Check all pods
kubectl get pods -A

# Check Gateway
kubectl get gateway,httproute -A

# Check Karpenter
kubectl get nodepool,ec2nodeclass -A
```

## Troubleshooting

### Flux not reconciling

```bash
flux logs -f
flux reconcile kustomization k8s-addons -n flux-system
```

### Certificate not issuing

```bash
kubectl describe certificate -n nginx-gateway
kubectl logs -n kube-system -l app.kubernetes.io/name=cert-manager
```

### DNS records not created

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns
```

## Cost Estimate

| Resource | ~Monthly Cost |
|----------|---------------|
| EKS Control Plane | $73 |
| NAT Gateway | $32 + data transfer |
| Network Load Balancer | $16 + data processing |
| EC2 (Spot) | Variable, depends on workload |
| **Minimum Total** | **~$150/month** |

Karpenter uses Spot instances for application workloads, reducing compute costs by ~70% compared to on-demand.

## Cleanup

```bash
terraform destroy
```

This removes everything including the EKS cluster, VPC, and S3 bucket.
