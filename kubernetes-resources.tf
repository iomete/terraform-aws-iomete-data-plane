# Description: Creates a secret in Kubernetes details for the iomete-controller
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

data "aws_caller_identity" "current" {}


resource "kubernetes_namespace" "iomete-system" {
  metadata {
    name   = "iomete-system"
  }
}

resource "kubernetes_secret" "data-plane-secret" {
  metadata {
    name      = "iomete-cloud-settings"
    namespace = "iomete-system"
  }

  data = {
    "settings" = jsonencode({
      cloud                 = "aws",
      region                = var.region,
      cluster_name          = var.cluster_name,
      storage_configuration = {
        lakehouse_bucket_name = var.lakehouse_bucket_name,
        lakehouse_role_arn    = aws_iam_role.lakehouse_role.arn,
      },
      eks = {
        name      = module.eks.cluster_name,
        endpoint  = module.eks.cluster_endpoint,
        admin_arn = data.aws_caller_identity.current.arn
      },
      terraform = {
        module_version = local.module_version
      }
    })
  }

  type = "opaque"

  depends_on = [
    module.karpenter,
    module.eks,
  ]
}

# =============== Istio Deployment ===============

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio-base" {
  name       = "base"
  namespace  = kubernetes_namespace.istio-system.metadata.0.name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.17.2"
  chart      = "base"
}

resource "helm_release" "istio-istiod" {
  name       = "istiod"
  namespace  = kubernetes_namespace.istio-system.metadata.0.name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.17.2"
  chart      = "istiod"
  depends_on = [
    helm_release.istio-base
  ]
}

resource "helm_release" "istio-gateway" {
  name       = "istio-ingress"
  namespace  = kubernetes_namespace.istio-system.metadata.0.name
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.17.2"
  chart      = "gateway"
  depends_on = [
    helm_release.istio-istiod
  ]
}

# =============== Karpenter Deployment ===============
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = kubernetes_namespace.karpenter.metadata.0.name
  repository = "https://chartmuseum.iomete.com"
  version    = "v0.19.3"
  chart      = "karpenter"
  depends_on = [
    module.karpenter,
    module.eks,
  ]

  values = [
    yamlencode({
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = module.karpenter.irsa_arn
        }
      },
      settings = {
        aws = {
          clusterName = module.eks.cluster_name
          clusterEndpoint = module.eks.cluster_endpoint
          defaultInstanceProfile = module.karpenter.instance_profile_name
          interruptionQueueName = module.karpenter.queue_name
          vmMemoryOverheadPercent = 0.045
        }
      },
      replicas = 1
    })
  ]
}
