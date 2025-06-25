terraform {
  backend "s3" {
    bucket = "kaushal2118terraformfinalbucket"
    key    = "us-west-1/terraform.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_availability_zones" "available" {}

#######################
# VPC & Networking
#######################
resource "aws_vpc" "kaushal2118" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
}

resource "aws_eip" "kaushal2118" {
  domain = "vpc"
}

resource "aws_nat_gateway" "kaushal2118" {
  allocation_id = aws_eip.kaushal2118.id
  subnet_id     = aws_subnet.public_1_kaushal2118.id
  depends_on    = [aws_internet_gateway.kaushal2118]
}

resource "aws_subnet" "public_1_kaushal2118" {
  vpc_id                  = aws_vpc.kaushal2118.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2_kaushal2118" {
  vpc_id                  = aws_vpc.kaushal2118.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1_kaushal2118" {
  vpc_id            = aws_vpc.kaushal2118.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_2_kaushal2118" {
  vpc_id            = aws_vpc.kaushal2118.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_route_table" "public_kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
}

resource "aws_route" "public_kaushal2118" {
  route_table_id         = aws_route_table.public_kaushal2118.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kaushal2118.id
}

resource "aws_route_table_association" "public_1_kaushal2118" {
  subnet_id      = aws_subnet.public_1_kaushal2118.id
  route_table_id = aws_route_table.public_kaushal2118.id
}

resource "aws_route_table_association" "public_2_kaushal2118" {
  subnet_id      = aws_subnet.public_2_kaushal2118.id
  route_table_id = aws_route_table.public_kaushal2118.id
}

resource "aws_route_table" "private_kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
}

resource "aws_route" "private_kaushal2118" {
  route_table_id         = aws_route_table.private_kaushal2118.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.kaushal2118.id
}

resource "aws_route_table_association" "private_1_kaushal2118" {
  subnet_id      = aws_subnet.private_1_kaushal2118.id
  route_table_id = aws_route_table.private_kaushal2118.id
}

resource "aws_route_table_association" "private_2_kaushal2118" {
  subnet_id      = aws_subnet.private_2_kaushal2118.id
  route_table_id = aws_route_table.private_kaushal2118.id
}

#######################
# Security Groups
#######################
resource "aws_security_group" "eks_nodes_kaushal2118" {
  name        = "eks-nodes-kaushal2118"
  description = "Allow traffic for EKS nodes"
  vpc_id      = aws_vpc.kaushal2118.id

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

resource "aws_security_group" "rds_kaushal2118" {
  name        = "rds-sg-kaushal2118"
  description = "Allow MySQL from EKS"
  vpc_id      = aws_vpc.kaushal2118.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.kaushal2118.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#######################
# RDS
#######################
resource "aws_db_subnet_group" "kaushal2118" {
  name       = "kaushal-db-subnet-group-kaushal2118"
  subnet_ids = [aws_subnet.private_1_kaushal2118.id, aws_subnet.private_2_kaushal2118.id]
}

resource "aws_db_instance" "kaushal2118" {
  identifier              = "kaushal-catalog-db-kaushal2118"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  username                = "admin"
  password                = "admin1234"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.kaushal2118.name
  vpc_security_group_ids  = [aws_security_group.rds_kaushal2118.id]
  publicly_accessible     = false
  backup_retention_period = 1
  db_name                 = "catalogdb"
  skip_final_snapshot     = true
}

#######################
# DynamoDB
#######################
resource "aws_dynamodb_table" "cart_kaushal2118" {
  name           = "kaushal-cart-kaushal2118"
  hash_key       = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "id"
    type = "S"
  }
}

#######################
# EKS Cluster
#######################
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "kaushal-cluster-kaushal2118"
  cluster_version = "1.29"
  subnet_ids      = [aws_subnet.private_1_kaushal2118.id, aws_subnet.private_2_kaushal2118.id]
  vpc_id          = aws_vpc.kaushal2118.id

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "kaushal-ng-kaushal2118"
      instance_types = ["t2.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      ami_type       = "AL2_x86_64"
      key_name       = "practise1"
    }
  }
}
