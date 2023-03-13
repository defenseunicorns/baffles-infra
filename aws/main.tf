data "aws_availability_zones" "available" {}
data "aws_partition" "current" {}

locals {
  cluster_name = "${var.name}-eks"

  admin_arns = [for admin_user in var.aws_admin_usernames : "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${admin_user}"]

  aws_auth_eks_map_users = [for admin_user in var.aws_admin_usernames : {
    userarn  = "arn:${data.aws_partition.current.partition}:iam::${var.account}:user/${admin_user}"
    username = "${admin_user}"
    groups   = ["system:masters"]
    }
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "${var.name}-vpc"
  cidr = "10.0.0.0/16"

  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets = ["10.0.2.0/24"]
  //create subnet in multiple availability zones to appease EKS
  private_subnets = [for k, v in module.vpc.azs : cidrsubnet(module.vpc.vpc_cidr_block, 5, k + 4)]

  enable_nat_gateway = true
  single_nat_gateway = true

  // Needed for private access to cluster
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# data "aws_security_group" "default" {
#   name   = "default"
#   vpc_id = module.vpc.vpc_id
# }

# data "aws_iam_policy_document" "generic_endpoint_policy" {
#   statement {
#     effect    = "Deny"
#     actions   = ["*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpc"

#       values = [module.vpc.vpc_id]
#     }
#   }
# }

# resource "aws_security_group" "vpc_tls" {
#   name        = "${var.name}-vpc_tls"
#   description = "Allow TLS inbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     description = "TLS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [module.vpc.vpc_cidr_block]
#   }

#   egress {
#     description = "TLS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = local.tags
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.24"

  # aws_region                            = var.region
  # aws_account                           = var.account

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # control_plane_subnet_ids        = module.vpc.private_subnets
  # source_security_group_id        = module.bastion.security_group_ids[0]
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # cluster_kms_key_additional_admin_arns = local.admin_arns
  # aws_auth_eks_map_users = local.aws_auth_eks_map_users

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    control-plane = {
      name = "control"

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      # pre_userdata can be used in both cases where you provide custom_ami_id or ami_type
      # pre_userdata = <<-EOT
      #   yum install -y amazon-ssm-agent
      #   systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
      # EOT

      # Taints can be applied through EKS API or through Bootstrap script using kubelet_extra_args
      # e.g., k8s_taints = [{key= "spot", value="true", "effect"="NO_SCHEDULE"}]
      k8s_taints = []

      # Node Labels can be applied through EKS API or through Bootstrap script using kubelet_extra_args
      k8s_labels = {}

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }

    # gen_workers = {
    #   name = "workers"

    #   instance_types = ["t3.small"]
    #   capacity_type  = "SPOT"

    #   # Taints can be applied through EKS API or through Bootstrap script using kubelet_extra_args
    #   # e.g., k8s_taints = [{key= "spot", value="true", "effect"="NO_SCHEDULE"}]
    #   k8s_taints = []

    #   # Node Labels can be applied through EKS API or through Bootstrap script using kubelet_extra_args
    #   k8s_labels = {}

    #   min_size     = 1
    #   max_size     = 2
    #   desired_size = 2
    # }

    bare_metal = {
      name           = "bare_metal"
      instance_types = ["c5.metal"]

      k8s_labels = {
        purpose = "vmi"
      }

      min_size     = 1
      max_size     = 1
      desired_size = 1
    }
  }
}
