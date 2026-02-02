# EKS Infrastructure with Kubernetes Add-ons

This project provisions a production-ready Amazon EKS cluster with essential Kubernetes add-ons including Karpenter for autoscaling, NGINX Ingress Controller, cert-manager for TLS certificates, and external-dns for automatic DNS management with Cloudflare.

## Features

- **EKS Cluster**: Managed Kubernetes cluster running version 1.33 in the `me-central-1` region
- **VPC**: Custom VPC with public, private, and intra subnets across 3 availability zones
- **Karpenter**: Cost-optimized node autoscaling using SPOT instances
- **NGINX Ingress Controller**: Production-ready ingress with automatic Load Balancer provisioning
- **cert-manager**: Automated TLS certificate management with Let's Encrypt
- **external-dns**: Automatic DNS record creation in Cloudflare
- **Sample Application**: Hextris game deployed at `hextris.souzaxx.dev`

## Architecture

The infrastructure automatically:
1. Creates an AWS Network Load Balancer (NLB) for the NGINX Ingress Controller
2. Registers the NLB in Cloudflare DNS
3. Configures DNS record `hextris.souzaxx.dev` to point to the load balancer
4. Provisions TLS certificates via Let's Encrypt for HTTPS

Karpenter is configured to use SPOT instances for cost-efficient workload scaling.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.7
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for Kubernetes cluster access
- Access to AWS account with permissions to create EKS, VPC, IAM resources
- Cloudflare account with API token

## Configuration

### Domain Configuration

This project is configured for the domain `souzaxx.dev`. To use your own domain:

1. **Update the domain in `main.tf`**:
   ```hcl
   external_dns = {
     enabled      = true
     extra_values = <<EOF
     # ... other config ...
     domainFilters:
       - your-domain.com  # Change this line
     EOF
   }
   ```

2. **Update the Cloudflare API token secret**:

   Edit the `kubernetes_secret.cf_token` resource in `main.tf` (lines 95-106):
   ```hcl
   resource "kubernetes_secret" "cf_token" {
     metadata {
       name      = "cloudflare-token"
       namespace = "kube-system"
     }

     data = {
       api-token = "YOUR_CLOUDFLARE_API_TOKEN"  # Replace with your token
     }

     type = "Opaque"
   }
   ```

3. **Update the Hextris ingress hostname** in `hextris.tf`:
   ```hcl
   hosts:
     - host: hextris.your-domain.com  # Change this
   ```

## Usage

### Deploy the Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

The apply process will:
- Create VPC, subnets, and NAT gateway
- Provision EKS cluster with managed node group for Karpenter
- Install Kubernetes add-ons (Karpenter, NGINX, cert-manager, external-dns)
- Deploy the Hextris sample application
- Create NLB and register DNS records automatically

### Access the Cluster

After deployment, configure kubectl:

```bash
aws eks update-kubeconfig --region me-central-1 --name tii-eks
```

### Verify Deployment

```bash
# Check cluster status
kubectl get nodes

# Check Karpenter
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# Check ingress controller
kubectl get svc -n ingress-nginx

# Check application
kubectl get ingress -n apps
```

### Destroy the Infrastructure

```bash
terraform destroy
```

This will remove all resources including the EKS cluster, VPC, load balancers, and DNS records.

## Cost Analysis

Cost estimation was performed using `infracost breakdown --path=.`:

```
Project: main

 Name  Monthly Qty  Unit  Monthly Cost

 OVERALL TOTAL                  $160.00

```

**Note**: The $160.00 estimate is due to Terraform variables not being provided during the static analysis. Actual costs will include:

- **EKS Cluster**: ~$73/month for control plane
- **EC2 Instances**: Variable based on Karpenter's SPOT instance scaling
  - Initial managed node group: 1x t3.xlarge SPOT instance (~$50-60/month with SPOT pricing)
  - Application nodes: Dynamic based on workload (Karpenter uses SPOT for ~70% cost savings)
- **NAT Gateway**: ~$32/month + data transfer costs
- **Network Load Balancer**: ~$16/month + data processing costs
- **Data Transfer**: Variable based on traffic

**Estimated Monthly Cost**: $150-200 with minimal workload, utilizing SPOT instances for cost optimization.

## Project Structure

```
.
├── README.md                  # This file
├── main.tf                    # Main EKS and VPC configuration
├── hextris.tf                 # Sample application deployment
├── providers.tf               # Provider configurations
├── versions.tf                # Terraform version constraints
├── variables.tf               # Input variables
├── modules/
│   └── k8s-addons/           # Kubernetes add-ons module
│       └── README.md         # Module documentation
└── charts/
    └── hextris/              # Hextris Helm chart
```

## Modules

- **k8s-addons**: Installs and configures Kubernetes add-ons including Karpenter, NGINX Ingress, cert-manager, AWS Load Balancer Controller, and external-dns. See [modules/k8s-addons/README.md](modules/k8s-addons/README.md) for detailed documentation.

## Security Considerations

- The Cloudflare API token is stored in a Kubernetes secret. Consider using AWS Secrets Manager or external-secrets operator for production.
- EKS cluster endpoint is publicly accessible. Consider restricting access via security groups.
- SPOT instances are used for cost optimization but may be interrupted. Ensure applications are fault-tolerant.

