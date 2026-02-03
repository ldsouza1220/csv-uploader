locals {
  cluster_name = var.eks.cluster_name
  oidc_issuer  = replace(var.eks.cluster_oidc_issuer_url, "https://", "")

  iam_role_names = {
    karpenter                    = "${local.cluster_name}-karpenter"
    karpenter_node               = "${local.cluster_name}-karpenter-node"
    aws_load_balancer_controller = "${local.cluster_name}-aws-lb-controller"
    external_dns                 = "${local.cluster_name}-external-dns"
  }

  tags = var.tags
}

#######################################
# Karpenter IAM
#######################################

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"
  create  = var.karpenter.enabled

  cluster_name = var.eks.cluster_name
  namespace    = "karpenter"

  node_iam_role_use_name_prefix = false
  node_iam_role_name            = local.iam_role_names.karpenter_node

  create_iam_role = true
  iam_role_name   = local.iam_role_names.karpenter

  create_pod_identity_association = true

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

#######################################
# AWS Load Balancer Controller IAM
#######################################

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role = var.aws_load_balancer_controller.enabled
  role_name   = local.iam_role_names.aws_load_balancer_controller

  provider_url                  = local.oidc_issuer
  role_policy_arns              = var.aws_load_balancer_controller.enabled ? [aws_iam_policy.aws_load_balancer_controller[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]

  tags = local.tags
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.aws_load_balancer_controller.enabled ? 1 : 0

  name = local.iam_role_names.aws_load_balancer_controller
  policy = templatefile("${path.module}/iam/aws-load-balancer-controller.json", {
    arn-partition = data.aws_partition.current.partition
  })

  tags = local.tags
}

#######################################
# External DNS IAM (for Route53)
#######################################

module "external_dns_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role = var.external_dns.enabled && var.external_dns.create_iam_role

  role_name    = local.iam_role_names.external_dns
  provider_url = local.oidc_issuer

  role_policy_arns              = var.external_dns.enabled && var.external_dns.create_iam_role ? [aws_iam_policy.external_dns[0].arn] : []
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:external-dns"]

  tags = local.tags
}

resource "aws_iam_policy" "external_dns" {
  count = var.external_dns.enabled && var.external_dns.create_iam_role ? 1 : 0

  name = local.iam_role_names.external_dns
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = local.tags
}

#######################################
# Flux CD Setup
#######################################

resource "kubernetes_secret" "flux_ssh" {
  count = var.flux.enabled && var.flux_deploy_key_private != "" ? 1 : 0

  metadata {
    name      = "flux-git-deploy-key"
    namespace = "flux-system"
  }

  data = {
    "identity"    = var.flux_deploy_key_private
    "known_hosts" = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.flux_system]
}

resource "kubernetes_namespace" "flux_system" {
  count = var.flux.enabled ? 1 : 0

  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "flux" {
  count = var.flux.enabled ? 1 : 0

  name             = "flux"
  namespace        = "flux-system"
  create_namespace = false
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  version          = var.flux.version

  wait = true

  depends_on = [
    kubernetes_namespace.flux_system,
    kubernetes_secret.flux_ssh
  ]
}

resource "kubectl_manifest" "flux_git_repository" {
  count = var.flux.enabled ? 1 : 0

  depends_on = [helm_release.flux, kubernetes_secret.flux_ssh]

  yaml_body = yamlencode({
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "csv-uploader"
      namespace = "flux-system"
    }
    spec = {
      interval = "5m"
      url      = "ssh://git@github.com/${var.flux.github_owner}/${var.flux.github_repository}.git"
      ref = {
        branch = var.flux.git_branch
      }
      secretRef = {
        name = "flux-git-deploy-key"
      }
    }
  })
}

resource "kubectl_manifest" "flux_kustomization" {
  count = var.flux.enabled ? 1 : 0

  depends_on = [kubectl_manifest.flux_git_repository]

  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "k8s-addons"
      namespace = "flux-system"
    }
    spec = {
      interval = "10m"
      sourceRef = {
        kind = "GitRepository"
        name = "csv-uploader"
      }
      path  = var.flux.kustomization_path
      prune = true
      wait  = true
      postBuild = {
        substitute = {
          CLUSTER_NAME               = var.eks.cluster_name
          CLUSTER_ENDPOINT           = var.eks.cluster_endpoint
          AWS_REGION                 = data.aws_region.current.name
          AWS_ACCOUNT_ID             = data.aws_caller_identity.current.account_id
          KARPENTER_ROLE_ARN         = var.karpenter.enabled ? module.karpenter.iam_role_arn : ""
          KARPENTER_NODE_ROLE_NAME   = var.karpenter.enabled ? local.iam_role_names.karpenter_node : ""
          KARPENTER_QUEUE_NAME       = var.karpenter.enabled ? module.karpenter.queue_name : ""
          AWS_LB_CONTROLLER_ROLE_ARN = var.aws_load_balancer_controller.enabled ? module.aws_load_balancer_controller_irsa.iam_role_arn : ""
          EXTERNAL_DNS_ROLE_ARN      = var.external_dns.enabled && var.external_dns.create_iam_role ? module.external_dns_irsa.iam_role_arn : ""
          VPC_ID                     = var.vpc_id
        }
      }
    }
  })
}

resource "kubectl_manifest" "flux_kustomization_configs" {
  count = var.flux.enabled ? 1 : 0

  depends_on = [kubectl_manifest.flux_kustomization]

  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "k8s-addons-configs"
      namespace = "flux-system"
    }
    spec = {
      interval = "10m"
      dependsOn = [
        {
          name = "k8s-addons"
        }
      ]
      sourceRef = {
        kind = "GitRepository"
        name = "csv-uploader"
      }
      path  = "infra/prod/k8s/flux-configs"
      prune = true
      wait  = true
    }
  })
}

resource "kubectl_manifest" "flux_kustomization_karpenter_configs" {
  count = var.flux.enabled && var.karpenter.enabled ? 1 : 0

  depends_on = [kubectl_manifest.flux_kustomization]

  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "karpenter-configs"
      namespace = "flux-system"
    }
    spec = {
      interval = "10m"
      dependsOn = [
        {
          name = "k8s-addons"
        }
      ]
      sourceRef = {
        kind = "GitRepository"
        name = "csv-uploader"
      }
      path  = "infra/prod/k8s/flux-karpenter-configs"
      prune = true
      wait  = true
      postBuild = {
        substitute = {
          CLUSTER_NAME             = var.eks.cluster_name
          KARPENTER_NODE_ROLE_NAME = local.iam_role_names.karpenter_node
        }
      }
    }
  })
}

resource "kubectl_manifest" "flux_kustomization_apps" {
  count = var.flux.enabled ? 1 : 0

  depends_on = [kubectl_manifest.flux_kustomization_configs]

  yaml_body = yamlencode({
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "apps"
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
      dependsOn = [
        {
          name = "k8s-addons-configs"
        }
      ]
      sourceRef = {
        kind = "GitRepository"
        name = "csv-uploader"
      }
      path  = "infra/prod/k8s/flux-apps"
      prune = true
      wait  = true
      postBuild = {
        substitute = {
          AWS_REGION = data.aws_region.current.name
        }
      }
    }
  })
}

#######################################
# Outputs
#######################################

output "karpenter_iam_role_arn" {
  description = "Karpenter controller IAM role ARN"
  value       = var.karpenter.enabled ? module.karpenter.iam_role_arn : null
}

output "karpenter_node_iam_role_name" {
  description = "Karpenter node IAM role name"
  value       = var.karpenter.enabled ? local.iam_role_names.karpenter_node : null
}

output "karpenter_queue_name" {
  description = "Karpenter interruption queue name"
  value       = var.karpenter.enabled ? module.karpenter.queue_name : null
}

output "aws_load_balancer_controller_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = var.aws_load_balancer_controller.enabled ? module.aws_load_balancer_controller_irsa.iam_role_arn : null
}

output "external_dns_iam_role_arn" {
  description = "External DNS IAM role ARN"
  value       = var.external_dns.enabled && var.external_dns.create_iam_role ? module.external_dns_irsa.iam_role_arn : null
}


