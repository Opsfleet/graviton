data "aws_region" "region" {}
data "aws_caller_identity" "account_id" {}
data "aws_availability_zones" "available" {}
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "graviton"
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnet_tags = {
    "karpenter.sh/discovery" = "private_subnet"
  }
  public_subnet_tags = {
    "karpenter.sh/discovery" = "public_subnet"
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "graviton"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true
  iam_role_name                  = "EKSClusterRole"
  iam_role_use_name_prefix       = false

  cluster_security_group_use_name_prefix = false
  node_security_group_name               = "graviton-nodes"
  node_security_group_use_name_prefix    = false

  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode(
        {
          tolerations : [
            {
              key : "type",
              operator : "Equal",
              value : "core",
              effect : "NoSchedule"
            }
          ]
        }
      )
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      configuration_values = jsonencode(
        {
          controller : {
            tolerations : [
              {
                key : "type",
                operator : "Equal",
                value : "core",
                effect : "NoSchedule"
              }
            ]
          }
        }
      )
    }
    aws-efs-csi-driver = {
      most_recent = true
      configuration_values = jsonencode(
        {
          controller : {
            tolerations : [
              {
                key : "type",
                operator : "Equal",
                value : "core",
                effect : "NoSchedule"
              }
            ]
          }
        }
      )
    }
  }

  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  control_plane_subnet_ids                 = module.vpc.private_subnets
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    core = {
      instance_types                  = ["t3.small"]
      ami_type                        = "BOTTLEROCKET_x86_64"
      platform                        = "bottlerocket"
      min_size                        = 3
      max_size                        = 3
      desired_size                    = 3
      iam_role_name                   = "ClusterNodeRole"
      iam_role_use_name_prefix        = false
      use_name_prefix                 = false
      launch_template_use_name_prefix = false

      taints = {
        core = {
          key    = "type"
          value  = "core"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name                  = module.eks.cluster_name
  iam_role_use_name_prefix      = false
  node_iam_role_name            = "KarpenterNodeRole"
  node_iam_role_use_name_prefix = false
  queue_name                    = "KarpenterQueue"
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "aws_eks_pod_identity_association" "karpetner" {
  cluster_name    = module.eks.cluster_name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = module.karpenter.iam_role_arn
}