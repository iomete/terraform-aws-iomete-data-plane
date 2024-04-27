data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

# Description: Creates a secret in Kubernetes details for the iomete-controller
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  # This token has 15 minutes TTL. If it takes longer than that to apply the resources, you will get unauthorized error. Just run `terraform apply` again.
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    # This token has 15 minutes TTL. If it takes longer than that to apply the resources, you will get unauthorized error. Just run `terraform apply` again.
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

locals {
  ca_bundle = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURTVENDQWpHZ0F3SUJBZ0lVQWhGNDlmWStpQU82c3FpSzdhRS81cHhxZ0hVd0RRWUpLb1pJaHZjTkFRRUwKQlFBd016RXhNQzhHQTFVRUF3d29jM0JoY21zdGIzQmxjbUYwYjNJdGQyVmlhRzl2YXk1cGIyMWxkR1V0YzNsegpkR1Z0TG5OMll6QWdGdzB5TkRBME1qTXlNRFEyTURCYUdBOHlNams0TURJd05qSXdORFl3TUZvd016RXhNQzhHCkExVUVBd3dvYzNCaGNtc3RiM0JsY21GMGIzSXRkMlZpYUc5dmF5NXBiMjFsZEdVdGMzbHpkR1Z0TG5OMll6Q0MKQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFMQ3FRRTZpUXdlZ042a096NXE4SVhxZQozSE5IT0NJNUI4NVVMbzU5bU5BakIvSmNaaFRySk9ZM0t6bDYxVTFMNmFuL3BOVks3azJoVWNiSUREakVJZG9BClVEdmpWUEFDZjR0SWYzUWVsdEhYS1ZCS3VTM1ZYOCtQRDdyN2V3VVhwTmRPZUFUQitNRUU4NVJvMTc5amRBSHEKN1B1a0o0TE5SNXllTm00citTczl1bEtIajI2NWxGZnRuWDBkSCt4RlBTVGdKVFloeVlnL3ZkR3V4M3Z5bmFVdgpZQW5TVnlReURnRVFLbkJDNWJ3Yk1mQU1lMzJCN0JjUy94VHA2clRsY2JmK3RnN3J2UDJKRkFGSFZ3ZStSUnlDClkrSEE5c25KdzBBOWl2NXBURzMxc3ZreDgvMmtEWmQwSEEzMVlxR0xwcHoxM1dyYnlBblBCOHhXdm5ib1Zzc0MKQXdFQUFhTlRNRkV3SFFZRFZSME9CQllFRkJxTTY0dno2d2tEbXZiV05jWDl3S3dlenRKWk1COEdBMVVkSXdRWQpNQmFBRkJxTTY0dno2d2tEbXZiV05jWDl3S3dlenRKWk1BOEdBMVVkRXdFQi93UUZNQU1CQWY4d0RRWUpLb1pJCmh2Y05BUUVMQlFBRGdnRUJBRTQ3Mlh0YnpGMDhxalhaVjdvVTY2Z2VreVdVbnJmc2oyMUlESjVMSzFFZENJdVcKS1Q1UVg0YWduUkl2SG0rR0NJaEZsZ0xQcW1HaC9KclRwZDdIS2VldkRxdnVZSXFDOHp5Vm1wSU9XNEhkTUU5QQoxeHoxN25menBGUkhDRjlmemE4aUZKL1picnJYR0k5SEpCdDRBUXdNQndtN1JSTFVmN1V1Wm5qdHl6aWV4NmhNCnFvajIyeDc5Yk9USC9tZm5NTU5USkZvVmJ1TG1XYzBnaHl0SE9uNGJWVjh5ckRCUjFyUFprWEhnMDg2ZmxUMSsKM0lHUyt4MXJSeDMyVE5FbzgvenBLb2NSc2pqTTVmL3UwZ3U5RDJmWHhOazlnTGFpTElaVFhIcU5DbEFBZmc4cApmVlJFQUh5QWtDa2RITGRMVUJPa0dOUWlHcE9kYlpJSnU0UEZoVmc9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
}

data "aws_caller_identity" "current" {}


resource "kubernetes_namespace" "iomete-system" {
  metadata {
    name = "iomete-system"
  }
}

resource "kubernetes_secret" "data-plane-secret" {
  metadata {
    name      = "iomete-cloud-settings"
    namespace = kubernetes_namespace.iomete-system.metadata[0].name
  }

  data = {
    "settings" = jsonencode({
      cloud                 = "aws",
      region                = data.aws_region.current.name,
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

resource "kubernetes_secret" "spark-operator-webhook-certs" {
  metadata {
    name      = "spark-operator-webhook-certs"
    namespace = kubernetes_namespace.iomete-system.metadata[0].name
  }

  binary_data = {
    "ca-cert.pem" : local.ca_bundle
    "ca-key.pem" : "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQ3dxa0JPb2tNSG9EZXAKRHMrYXZDRjZudHh6UnpnaU9RZk9WQzZPZlpqUUl3ZnlYR1lVNnlUbU55czVldFZOUyttcC82VFZTdTVOb1ZIRwp5QXc0eENIYUFGQTc0MVR3QW4rTFNIOTBIcGJSMXlsUVNya3QxVi9QancrNiszc0ZGNlRYVG5nRXdmakJCUE9VCmFOZS9ZM1FCNnV6N3BDZUN6VWVjbmpadUsva3JQYnBTaDQ5dXVaUlg3WjE5SFIvc1JUMGs0Q1UySWNtSVA3M1IKcnNkNzhwMmxMMkFKMGxja01nNEJFQ3B3UXVXOEd6SHdESHQ5Z2V3WEV2OFU2ZXEwNVhHMy9yWU82N3o5aVJRQgpSMWNIdmtVY2dtUGh3UGJKeWNOQVBZcithVXh0OWJMNU1mUDlwQTJYZEJ3TjlXS2hpNmFjOWQxcTI4Z0p6d2ZNClZyNTI2RmJMQWdNQkFBRUNnZ0VBRGFCMTFmcm42N0pjN3lKRG9XUzlVL1BsbUo4a204ekZXaEhST2VsMllzSDgKTHFKK2hBK05OWlJXYVV1RFZFQWJEenpxVkhYWjNHWjJNUWxYelpmdHVvVlVSSnZvNVFJTjdFcnVMMjRRLzM0RApmUlhrMW9xREpvT0J2emFZMStuUUVoNUdxa1RoL1c4UVBaUnRHS0YwSHBZbDN0VW92UXNKNlBFK3pQYUJKODRUCmtoT0tEKy9kL1dZSzRtKzE0bGx1TU43S2ZuTkk2Wll2djVqQlF1a1ZjZXJ5VWN1MVB0OVc3SzVBY0haRDRsM3MKcU5TbVc4azd6bEpQSFIvSExLNjdtOHRnNU54K2NpTS9zZXlhWHJXSGFsMDJPbG5MajJDRXFPMGxyVUNOUW93KwpTZ3Q3ZGpmNm9kby81R2E3RW8wZjJaaDkrM0ZYVW01K1NVZXRibnlnS1FLQmdRRGMvc3R5M0QzVUQ1SDJsMUFECmg1TCt1UkU1cFAyUTFqZE53R3Bma2lzcFVVdWxieThpQ2x3cENvQ3FkMGxpTVdiZjhmaWFmVVg2dFlxVVROWDYKY2ZGN2R1OUR1R2hMR3dHNzcvaW94SWdudHNMd3RDU0ExbEFCRGpwVXhqWWZ1dXFTWHExWkx0eU02bkpueGc3bwo4YVczQkdITkVyVit3Q0lWVHN6QVVNU2ErUUtCZ1FETXBlVlJKbHlFMUt6T2RjL1pmMVZMS2FBUmJnbWZBNHFMCms3WGtPeEtEVjh0amRseC93MmZjR1lwRnkxOFM2WnlxQXF1ZmQrdnpCaWl0UUtHangyNlB1UjRvb0drb0FiL3MKc1dHcXFwWTR5ajdRbERjeVZJLzJrNzJ3dmgydnhxR3dZYldWMHhPbEwrR3Fkc0RIWUxieCthUkJWQmpXYXdoYQo0VVBUNmxsTTR3S0JnQVlnaGxGNzY3YnFhNWlUbjJOSnFmaW45dU5MUU1CNFAvWkc1R3diNkZodjZaSC9vQ1hvCmRaK3BxK0dPQnhuUzF0QlVyQmpVYWxGR0lUNTFWdVZuclZOSCsrQTd4NkIxY2puY3NGODFlN1RtSzBkekp5UHYKVFM2S1QzRzBRU0htRThUVkhTZEExbHFOMFhneEZJNit6R0pqbTdhTTB6MWRaRlNFNThaWk51bzVBb0dCQUlzZgphSkxQV213dXpMK2FsYytOWWVXMENZNXYyUGlTQnJpMmxSdndFTGpia1hndmVkaWRkZGpLUUJjTWw3aWF1aGRWCnMyaTR0TjNFM1JoUzdOQVRmeFVUeXUzaGh6dGNYU1pDdkZ1eWxtZExEb0xyajg2V2NEdzMyZWZ5aHVuOVJlUkwKdUk5L0xFYkxFMFc0YjN2YlF1T2pTOGZoclBUdlZJRzd6RW1mY2svekFvR0FPMHpiQjRvbXgwaERsc1hrcG0zbwpUWmdFck1wT3ZhT1BxNGdXeisxRUcyQldxVGRXWlAvT2VHRWVXdXZjR1RLRTdtNWpHcE50b0xCcVpkZFNMSmZvClBVd0VQNDNRV2EzLzdrRHNCN3ovZ3QxZXEvcVNjdzVCMmdRbWlRUnhXWjg2dTQ1bnNxNzU2bkoyV1V1Z082clkKY2luTldXU1FBT3FTYmQ5RnNrS2NlR1E9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K"
    "server-cert.pem" : "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURwakNDQW82Z0F3SUJBZ0lVYUtLZnlocFpEV2VZV3AxQktSWHg5K1dLWXhjd0RRWUpLb1pJaHZjTkFRRUwKQlFBd016RXhNQzhHQTFVRUF3d29jM0JoY21zdGIzQmxjbUYwYjNJdGQyVmlhRzl2YXk1cGIyMWxkR1V0YzNsegpkR1Z0TG5OMll6QWdGdzB5TkRBME1qTXlNRFEyTURCYUdBOHlNams0TURJd05qSXdORFl3TUZvd016RXhNQzhHCkExVUVBd3dvYzNCaGNtc3RiM0JsY21GMGIzSXRkMlZpYUc5dmF5NXBiMjFsZEdVdGMzbHpkR1Z0TG5OMll6Q0MKQVNJd0RRWUpLb1pJaHZjTkFRRUJCUUFEZ2dFUEFEQ0NBUW9DZ2dFQkFMR1o5TE9kaDYzSDdSYm1VMkxsYlc3MwpYVnFBN3hmdTdXYjkrUUlveVVxVFI4ZGFLdG5XYnN3TWdyQmxLcHQ5Rmd4WVIzR0JSTXNVb0x1UFJ0WkZDOXlmCkpVMC9hUUlKMERBV2hteU5YUkhEaXRjUUEzNkRtRVdMOEFOQWlFL1VLVU5SQ2VGTTZYSEpLaHNjcjhFWndjR24KQjNXYkNLTUJiajl0NlA3aGJzYUNjaENKak9FaXZWa1hNS1o1U0hCYlhLMkVtZXphSG5EQS82Q2JDUjVvejlmaQpkSlVMY0pibFFLSW1FMHlnL25JUlZzMk5UcldPMTRzMExwVmVlT3VRbXZoUGhqb0FCeVppVVdtZVYwUE1FdGhCCmhJeDdYcTU5WjZJbHBJYnkydlY5MEZGWTBFa3hKZFhxMW9ZcysvajBLTGtOTloyYUE2azZwcmJGaHFrN1J4VUMKQXdFQUFhT0JyekNCckRBSkJnTlZIUk1FQWpBQU1Bc0dBMVVkRHdRRUF3SUY0REFkQmdOVkhTVUVGakFVQmdncgpCZ0VGQlFjREFnWUlLd1lCQlFVSEF3RXdNd1lEVlIwUkJDd3dLb0lvYzNCaGNtc3RiM0JsY21GMGIzSXRkMlZpCmFHOXZheTVwYjIxbGRHVXRjM2x6ZEdWdExuTjJZekFkQmdOVkhRNEVGZ1FVWDkxSVNuTkpaNzVPMkU1bHFsMkcKb2s3VTk4Z3dId1lEVlIwakJCZ3dGb0FVR296cmkvUHJDUU9hOXRZMXhmM0FyQjdPMGxrd0RRWUpLb1pJaHZjTgpBUUVMQlFBRGdnRUJBQ3RQaXhpb2FUdnZ0MjR1MzQvTng3aVg3ZjNlUVc0dW9scXh1dWxFZUJ2VVhaZUlQd2NECldyOUFhNDVpUlFHWlREeFREcVRreUlxWmtvYlBySVRmczZvN2lpUEQ4Q2hCcFJVRDVEYWFzUE11eFkzOXhVNnoKV2lMMWJMMzVhcjZqdkZCaFFlcUJ1M0puUXA3SWRxQlNwNFhRRUhmcGNmczc4SXRJMEVvQnR2cFRBSjFuSWZnZQpXVCt1TWl1ay81cjJTRkpUZTE4ZURMczQ1ejdzMEliS1hNQ2RvdEJmaVZmWEpTc1hwcitXR0ZEZDRsdTE2S2oyCkp1SzZvZ1QvNExaYk5ZSTBJTFpna0NyelFDSGFjcjhxY2xFT3VBVjZIbE1VZXRQeWhKR3ZlbVZSSmFvakVJTVAKNEJwejI5ejJST3ZjeEV2ekRSbGRWdml3dVJ0d0hVazJRVEE9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    "server-key.pem" : "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQ3htZlN6bllldHgrMFcKNWxOaTVXMXU5MTFhZ084WDd1MW0vZmtDS01sS2swZkhXaXJaMW03TURJS3daU3FiZlJZTVdFZHhnVVRMRktDNwpqMGJXUlF2Y255Vk5QMmtDQ2RBd0ZvWnNqVjBSdzRyWEVBTitnNWhGaS9BRFFJaFAxQ2xEVVFuaFRPbHh5U29iCkhLL0JHY0hCcHdkMW13aWpBVzQvYmVqKzRXN0dnbklRaVl6aElyMVpGekNtZVVod1cxeXRoSm5zMmg1d3dQK2cKbXdrZWFNL1g0blNWQzNDVzVVQ2lKaE5Nb1A1eUVWYk5qVTYxanRlTE5DNlZYbmpya0pyNFQ0WTZBQWNtWWxGcApubGREekJMWVFZU01lMTZ1ZldlaUphU0c4dHIxZmRCUldOQkpNU1hWNnRhR0xQdjQ5Q2k1RFRXZG1nT3BPcWEyCnhZYXBPMGNWQWdNQkFBRUNnZ0VBV0tNQm9YTUplQTNEb2g0cGw3M3hNK1I0enVaeWJYdHRPRzJnalJkVi9zWXEKbUsvRG14eU9CNEJtNlNwVWJXMnNSMVQzc3dwVkR4V29jbk03WTB6cWNwMXF2SGJkTFl0QVAvKzk3d2RPWDhNNwowOEhHUEtub29TMEtDRlY0c242c2FWQlVvZ0VFc1NrNHZuYytzQnp1dW50bUdhZmFVNkF2S2JEdEMrZnVwVnMxCnArUG50NVFOeVVhZE9PcjRaRjd2dUc3eE04ZGZONDd6MDcybWxZK05iSXZtUVdCb0dKM0g1M0RXS2pvemx2VEYKOEQzN0M3UnEzWGpZaGhsYktMeVhJNk00V1h6a21aK0V4dkhOelpYZkc5VnQzZ0VrbjNLWHppNjVWdDVTaElsbApMbGpLb21pTVcxRlFGcVNwcXlwVDU3UEprd1pYbjRkRVNXQXcyRjYrc1FLQmdRRDVWbEpHMVFCck5GOWlpV2VHCjlDMmlXanhaK3JVRUlPcDlhWm5DamgzTFZNTGRkRGZ1U0NMdWhCaWc5S0RVWVZVQXZTcnlDdy95OS9VaytVaWoKeVFCTEFHNzI0OW9aWWRKYUt6d2RGUXdURFk2MjJLeVNxeW5aZitzdmpucWhuUzQ5d3VpTUJDanZHVUYyOTlhMQpsZTdXME54WUw0bEhzUXZDY1pZVnE2cU9qd0tCZ1FDMldPYUkvSXQ0dENJN0FRdzhSdzRyV1lYWmpMUm5maWZoCmxsTUFPT1hIRmlIYWxlVVBsdkJtclQ4V1pzWmJWWVBaekJxRWFjR2V0cmcrYnZUck1MZHlqNkw2ZnZhVFpTc0QKSHdaZG9KWUN1S2xGMVVCMENPZTlGcS85QlE3TkorRUxUNDdZcEM1eklUMHVCelZ1WGhzRjhJVmlmdERBcnFhawp4aUx1cjF6aUd3S0JnUUQ0YUt6dUR0WXMrRyt6anl1S2c0bFhmOGt5NkJraU5OMEo5NFNPRmVMUEtmSStpY1FUCmJPRUllcWpDNnhXMG9nZjdCWHhjeXZLbjRhdmxtMHBvaXgvMG1VajBSb3VLMEMrdlQvWERENjRJNlcvdThTMzEKcmZ1eXlzUDRqRjNXMSs4eTd4V2FNYWJLbDRIbVVnTWl4RzdBckROcTFHbFQrS3E3blVpbTdIR3ZOd0tCZ0c3NgpJQ1JTLzFkUTJseHF3TldXc1NyMDZ4K0NJUEd6dC9YMWxVSlhYcEVTQ1R5TmFjRlpMYXB2Mml0NkZWTFU4dEFGCkJrWjhUdGlYZi82UGJRUU92RGMrOEFQZ2JaVTdSemc1RTVpNytWQmlyckxQbk5DQjh2Z0Q3TXZpM2lWQ0ZoYmEKTHFmdkZFNEJkc2lpbm9RelJlTVJoVHh5emYzV3paa085WWVxdHE3dEFvR0FOWUpmU3Z6MXJHUGJ0U2ZVRjZjbQpLZHcySVRnWVl2eGZYMEthbmtZNjkrRmxFU2JldU9pbGhHbHBuNXRmZ0hSb1ZGY1RkcVlyaWNKKzlZVnYyaXdMCkF1M1NnVXdkM1R1MC9KWnZ3cmJESjU1UlJXQmxLZDk2dy9kaGJNVlIzVkovYXhjdHhDWXE0SGhVa2xnVzhJVy8KZWdTbWJ1Y0NoS0s3NTN1TjB0dlUwSzg9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K"
  }

  type = "Opaque"
}

resource "helm_release" "iomete-data-plane-base" {
  name       = "data-plane-base"
  namespace  = kubernetes_namespace.iomete-system.metadata.0.name
  repository = "https://chartmuseum.iomete.com"
  version    = "1.9.3"
  chart      = "iomete-data-plane-base"

  set {
    name  = "caBundle"
    value = local.ca_bundle
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lakehouse_role.arn
  }

  depends_on = [
    kubernetes_secret.spark-operator-webhook-certs,
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
