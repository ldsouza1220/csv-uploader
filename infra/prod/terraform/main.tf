locals {
  name   = "ounass-eks"
  region = "me-central-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Example    = local.name
    GithubRepo = "csv-uploader"
    GithubOrg  = "ldsouza1220"
  }
}

data "aws_availability_zones" "available" {}

#######################################
# EKS Cluster
#######################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name
  kubernetes_version = "1.35"

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.xlarge", "c5d.xlarge"]
      capacity_type  = "SPOT"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      labels = {
        "karpenter.sh/controller" = "true"
      }
    }
  }

  node_security_group_tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.name
  })

  tags = local.tags
}

#######################################
# VPC
#######################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}

#######################################
# EBS CSI Driver IAM Role
#######################################

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role = true
  role_name   = "${local.name}-ebs-csi"

  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]

  tags = local.tags
}

#######################################
# CSV Uploader IAM Role (EKS Pod Identity)
#######################################

resource "aws_iam_role" "csv_uploader" {
  name = "${local.name}-csv-uploader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "csv_uploader_s3" {
  name = "s3-upload"
  role = aws_iam_role.csv_uploader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::csv-uploader-ounass",
          "arn:aws:s3:::csv-uploader-ounass/*"
        ]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "csv_uploader" {
  cluster_name    = module.eks.cluster_name
  namespace       = "apps"
  service_account = "csv-uploader"
  role_arn        = aws_iam_role.csv_uploader.arn

  depends_on = [module.eks]
}

#######################################
# Cloudflare Secret (for cert-manager & external-dns)
#######################################

resource "kubernetes_secret" "cloudflare_token" {
  metadata {
    name      = "cloudflare-token"
    namespace = "kube-system"
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  type = "Opaque"
}

#######################################
# K8s Addons (IAM Roles + Flux)
#######################################

module "k8s_addons" {
  source = "./modules/k8s-addons"

  eks = {
    cluster_name            = module.eks.cluster_name
    cluster_endpoint        = module.eks.cluster_endpoint
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  }

  vpc_id = module.vpc.vpc_id
  domain = var.domain
  tags   = local.tags

  karpenter = {
    enabled = true
  }

  aws_load_balancer_controller = {
    enabled = true
  }

  cert_manager = {
    enabled = true
  }

  external_dns = {
    enabled         = true
    create_iam_role = false
  }

  flux = {
    enabled            = true
    github_owner       = "ldsouza1220"
    github_repository  = "csv-uploader"
    git_branch         = "main"
    kustomization_path = "infra/prod/k8s/flux"
  }

  flux_deploy_key_private = var.flux_deploy_key_private

  depends_on = [
    module.eks,
    kubernetes_secret.cloudflare_token
  ]
}

#######################################
# Outputs
#######################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "karpenter_iam_role_arn" {
  description = "Karpenter controller IAM role ARN"
  value       = module.k8s_addons.karpenter_iam_role_arn
}

output "karpenter_node_iam_role_name" {
  description = "Karpenter node IAM role name"
  value       = module.k8s_addons.karpenter_node_iam_role_name
}

output "aws_load_balancer_controller_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = module.k8s_addons.aws_load_balancer_controller_iam_role_arn
}
