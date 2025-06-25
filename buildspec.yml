provider "aws" {
  region = "us-west-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "terraform-cluster"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    node-group-1 = {
      instance_types = ["t2.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }

    node-group-2 = {
      instance_types = ["t2.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
    }
  }

  enable_irsa = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "terraform-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-west-1a", "us-west-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
