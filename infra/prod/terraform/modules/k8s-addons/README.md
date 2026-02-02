# K8s Add-ons Module

This Terraform module installs and configures essential Kubernetes add-ons for a production-ready EKS cluster.

## Add-ons Included

- **Karpenter**: Kubernetes node autoscaler that provisions right-sized compute resources using SPOT instances for cost optimization
- **NGINX Ingress Controller**: Production-grade ingress controller for routing external traffic
- **AWS Load Balancer Controller**: Manages AWS Elastic Load Balancers for Kubernetes services
- **cert-manager**: Automates TLS certificate management with Let's Encrypt integration
- **external-dns**: Automatically manages DNS records in Cloudflare based on Kubernetes ingress resources

## Features

- IRSA (IAM Roles for Service Accounts) integration for secure AWS API access
- Automated TLS certificate provisioning with Let's Encrypt
- Automatic DNS record creation in Cloudflare
- Karpenter configured with SPOT instances for cost-efficient node scaling
- Pre-configured cluster issuers for production and staging certificates

## Usage

```hcl
module "k8s-addons" {
  source = "./modules/k8s-addons"

  eks = {
    cluster_name            = module.eks.cluster_name
    cluster_endpoint        = module.eks.cluster_endpoint
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  }

  karpenter = {
    enabled = true
  }

  ingress_nginx = {
    enabled = true
  }

  aws_load_balancer_controller = {
    enabled      = true
    extra_values = <<EOF
    vpcId: "${module.vpc.vpc_id}"
    EOF
  }

  cert_manager = {
    enabled = true
  }

  external_dns = {
    enabled      = true
    extra_values = <<EOF
    provider:
      name: cloudflare

    env:
      - name: CF_API_TOKEN
        valueFrom:
          secretKeyRef:
            name: cloudflare-token
            key: api-token

    domainFilters:
      - your-domain.com
    EOF
  }
}
```

## Karpenter Configuration

Karpenter is configured to use SPOT instances for cost optimization. The module includes:

- NodePool definitions for workload-specific scaling
- EC2NodeClass configurations for AWS integration
- Automatic instance type selection based on workload requirements
- SPOT instance prioritization for ~70% cost savings


## DNS Management

external-dns automatically creates and updates DNS records in Cloudflare when you create Ingress resources. No manual DNS configuration required.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| aws | >= 5.27 |
| helm | ~> 3.0 |
| kubectl | ~> 2.0 |
| kubernetes | ~> 2.0, != 2.12 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.27 |
| helm | ~> 3.0 |
| kubectl | ~> 2.0 |
| time | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| iam\_assumable\_role\_aws\_load\_balancer\_controller | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | ~> 5.0 |
| karpenter | terraform-aws-modules/eks/aws//modules/karpenter | 21.8.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.ingress_nginx](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.cert_manager_cluster_issuers](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.hextris_karpenter_](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.hextris_karpenter_node_pool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [time_sleep.cert_manager_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.karpenter_manager_sleep](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [kubectl_path_documents.cert_manager_cluster_issuers](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/data-sources/path_documents) | data source |
| [kubectl_path_documents.hextris_karpenter_node_class](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/data-sources/path_documents) | data source |
| [kubectl_path_documents.hextris_karpenter_node_pool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/data-sources/path_documents) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| arn\_partition | n/a | `any` | `{}` | no |
| aws\_load\_balancer\_controller | n/a | `any` | `{}` | no |
| cert\_manager | n/a | `any` | `{}` | no |
| eks | n/a | <pre>object({<br/>    cluster_name            = string<br/>    cluster_endpoint        = string<br/>    cluster_oidc_issuer_url = string<br/>  })</pre> | n/a | yes |
| external\_dns | n/a | `any` | `{}` | no |
| helm\_defaults | Customize default Helm behavior | `any` | `{}` | no |
| ingress\_nginx | Customize ingress-nginx chart, see `nginx-ingress.tf` for supported values | `any` | `{}` | no |
| karpenter | n/a | `any` | `{}` | no |

## Outputs

No outputs.

---

*This documentation was generated using `terraform-docs markdown table .`*
