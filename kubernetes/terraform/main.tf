locals {
  region = "eu-central-1"
}

provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = local.region
}

module "eks_clickhouse" {
  source  = "github.com/Altinity/terraform-aws-eks-clickhouse"

  # Do not install Kubernetes operator or sample ClickHouse cluster. 
  install_clickhouse_operator = false
  install_clickhouse_cluster  = false

  # Set to true if you want to use a public load balancer (and expose ports to the public Internet)
  clickhouse_cluster_enable_loadbalancer = false

  eks_cluster_name = "osmola-eks-cluster"
  eks_region       = local.region
  eks_cidr         = "10.0.0.0/16"
  eks_cluster_version = "1.32"

  eks_availability_zones = [
    "${local.region}a"
    , "${local.region}b"
    , "${local.region}c"
  ]
  eks_private_cidr = [
    "10.0.4.0/22"
    , "10.0.8.0/22"
    , "10.0.12.0/22"
  ]
  eks_public_cidr = [
    "10.0.100.0/22"
    , "10.0.104.0/22"
    , "10.0.108.0/22"
  ]

  eks_node_pools = [
    {
      name          = "clickhouse-nvme-swarm"
      instance_type = "i8g.xlarge"
      ami_type      = "AL2023_ARM_64_STANDARD"
      desired_size  = 0
      max_size      = 20
      min_size      = 0
      zones         = ["${local.region}a"]
      # zones         = ["${local.region}a", "${local.region}b", "${local.region}c"]
      taints        = [{
         key    = "antalya"
         value  = "nvme-swarm"
         effect = "NO_SCHEDULE"
      }]
      labels        = {
         "aws.amazon.com/eks-local-ssd" = "true"
      }
      # This should add a tag on the EKS node group but does not.
      # Add the tag manually. See
      # https://github.com/Altinity/terraform-aws-eks-clickhouse/issues/27
      tags = {
        "k8s.io/cluster-autoscaler/node-template/label/aws.amazon.com/eks-local-ssd" = "true"
      }
    },
    {
      name          = "system"
      instance_type = "t4g.large"
      ami_type      = "AL2023_ARM_64_STANDARD"
      desired_size  = 1
      max_size      = 10
      min_size      = 0
      zones         = ["${local.region}a"]
    }
  ]

  eks_tags = {
    CreatedBy = "antalya-test"
  }
}
