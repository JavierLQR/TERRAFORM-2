terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.region_name
}

resource "random_pet" "this" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = "nestjs-terraform-eks-cluster"
  cluster_version = "1.32"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id


  # OIDC (enabled by default en v20+)
  enable_irsa = true
  eks_managed_node_groups = {
    ng-1 = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
    }
  }
  # EKS probar conectar with VPC CNI
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true


  tags = {
    Environment = var.node_env
    Terraform   = "true"
    Name        = "nestjs-terraform-eks-cluster"
    Owner       = var.owner

  }
}
# aws-auth to configure kubectl
module "aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.8.5"

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::222634373780:root"
      username = "root"
      groups   = ["system:masters"]
    }
  ]

  depends_on = [module.eks]
}
