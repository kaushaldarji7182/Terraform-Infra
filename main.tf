terraform {
  backend "s3" {
    bucket = "terraform-sujeet-update"
    key    = "us-west-1/terraform.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "kaushal_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "kaushal_igw" {
  vpc_id = aws_vpc.kaushal_vpc.id
}

resource "aws_subnet" "kaushal_public_1" {
  vpc_id                  = aws_vpc.kaushal_vpc.id
  cidr_block              = var.public_subnet_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "kaushal_public_2" {
  vpc_id                  = aws_vpc.kaushal_vpc.id
  cidr_block              = var.public_subnet_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "kaushal_private_1" {
  vpc_id            = aws_vpc.kaushal_vpc.id
  cidr_block        = var.private_subnet_1
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "kaushal_private_2" {
  vpc_id            = aws_vpc.kaushal_vpc.id
  cidr_block        = var.private_subnet_2
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_eip" "kaushal_nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "kaushal_nat" {
  allocation_id = aws_eip.kaushal_nat_eip.id
  subnet_id     = aws_subnet.kaushal_public_1.id
}

resource "aws_route_table" "kaushal_public_rt" {
  vpc_id = aws_vpc.kaushal_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kaushal_igw.id
  }
}

resource "aws_route_table" "kaushal_private_rt" {
  vpc_id = aws_vpc.kaushal_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kaushal_nat.id
  }
}

resource "aws_route_table_association" "kaushal_pub1_assoc" {
  subnet_id      = aws_subnet.kaushal_public_1.id
  route_table_id = aws_route_table.kaushal_public_rt.id
}

resource "aws_route_table_association" "kaushal_pub2_assoc" {
  subnet_id      = aws_subnet.kaushal_public_2.id
  route_table_id = aws_route_table.kaushal_public_rt.id
}

resource "aws_route_table_association" "kaushal_priv1_assoc" {
  subnet_id      = aws_subnet.kaushal_private_1.id
  route_table_id = aws_route_table.kaushal_private_rt.id
}

resource "aws_route_table_association" "kaushal_priv2_assoc" {
  subnet_id      = aws_subnet.kaushal_private_2.id
  route_table_id = aws_route_table.kaushal_private_rt.id
}

resource "aws_security_group" "kaushal_eks_nodes" {
  name        = "kaushal-eks-nodes-final"
  description = "Allow all traffic for EKS nodes"
  vpc_id      = aws_vpc.kaushal_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kaushal_rds" {
  name        = "kaushal-rds-sg-final"
  description = "Allow MySQL from EKS"
  vpc_id      = aws_vpc.kaushal_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "kaushal_rds" {
  name       = "kaushal-db-subnet-group-final"
  subnet_ids = [aws_subnet.kaushal_private_1.id, aws_subnet.kaushal_private_2.id]
}

resource "aws_db_instance" "kaushal_rds" {
  identifier              = "kaushal-catalog-db-final"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.kaushal_rds.name
  vpc_security_group_ids  = [aws_security_group.kaushal_rds.id]
  publicly_accessible     = false
  backup_retention_period = 1
  db_name                 = "catalogdb"
  skip_final_snapshot     = true
}

resource "aws_dynamodb_table" "kaushal_cart" {
  name           = "kaushal-cart-final"
  hash_key       = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "id"
    type = "S"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"
  cluster_name    = "kaushal-cluster-final"
  cluster_version = "1.29"
  vpc_id          = aws_vpc.kaushal_vpc.id

  subnet_ids = [
    aws_subnet.kaushal_private_1.id,
    aws_subnet.kaushal_private_2.id
  ]

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "kaushal-node-group-final"
      desired_size   = var.eks_desired_size
      max_size       = var.eks_max_size
      min_size       = var.eks_min_size
      instance_types = ["t2.medium"]
      key_name       = "practise1"
    }
  }
}
