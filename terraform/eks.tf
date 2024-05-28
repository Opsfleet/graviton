module "eks" {
  version = "20.11.0"
  source  = "terraform-aws-modules/eks/aws"

  cluster_name                   = "graviton"
  cluster_version                = "1.29"
  cluster_enabled_log_types      = []
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
  version = "20.11.1"

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
