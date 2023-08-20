provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.13"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = [var.instance_type]

      min_size     = 1
      max_size     = 3  # Dev size
      desired_size = 2  # Dev size
    }
  }

  tags = var.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  manage_default_vpc = true

  name = var.cluster_name
  cidr = var.vpc_cidr
  
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  private_subnets = [for k in range(3) : cidrsubnet(var.vpc_cidr, 4, k)]
 
  enable_nat_gateway = false

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.1"

  vpc_id = module.vpc.vpc_id

  # Security group
  create_security_group      = true
  security_group_name_prefix = "${var.cluster_name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = merge({
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = {
        Name = "${var.cluster_name}-s3"
      }
    }
    },
    { for service in toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"]) :
      replace(service, ".", "_") =>
      {
        service             = service
        subnet_ids          = module.vpc.private_subnets
        private_dns_enabled = true
        tags                = { Name = "${var.cluster_name}-${service}" }
      }
  })

  tags = var.tags
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Policy for pod S3 access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "s3:GetObject",
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.example_bucket.arn}/*"
      }
    ],
  })
}

resource "aws_iam_role" "pod_role" {
  name = "pod-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.pod_role.name
}
