terraform {
  backend "s3" {
    bucket = "kaushal2118terraformfinalbucket"
    key    = "us-west-1/terraform-kaushal2118v2.tfstate"
    region = "us-west-1"
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "kaushal2118v2" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "kaushal2118v2" {
  vpc_id = aws_vpc.kaushal2118v2.id
}

resource "aws_subnet" "public_1_kaushal2118v2" {
  vpc_id                  = aws_vpc.kaushal2118v2.id
  cidr_block              = var.public_subnet_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2_kaushal2118v2" {
  vpc_id                  = aws_vpc.kaushal2118v2.id
  cidr_block              = var.public_subnet_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1_kaushal2118v2" {
  vpc_id            = aws_vpc.kaushal2118v2.id
  cidr_block        = var.private_subnet_1
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_2_kaushal2118v2" {
  vpc_id            = aws_vpc.kaushal2118v2.id
  cidr_block        = var.private_subnet_2
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_eip" "nat_kaushal2118v2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "kaushal2118v2" {
  allocation_id = aws_eip.nat_kaushal2118v2.id
  subnet_id     = aws_subnet.public_1_kaushal2118v2.id
  depends_on    = [aws_internet_gateway.kaushal2118v2]
}

resource "aws_route_table" "public_kaushal2118v2" {
  vpc_id = aws_vpc.kaushal2118v2.id
}

resource "aws_route" "public_kaushal2118v2" {
  route_table_id         = aws_route_table.public_kaushal2118v2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kaushal2118v2.id
}

resource "aws_route_table_association" "public_1_kaushal2118v2" {
  subnet_id      = aws_subnet.public_1_kaushal2118v2.id
  route_table_id = aws_route_table.public_kaushal2118v2.id
}

resource "aws_route_table_association" "public_2_kaushal2118v2" {
  subnet_id      = aws_subnet.public_2_kaushal2118v2.id
  route_table_id = aws_route_table.public_kaushal2118v2.id
}

resource "aws_route_table" "private_kaushal2118v2" {
  vpc_id = aws_vpc.kaushal2118v2.id
}

resource "aws_route" "private_kaushal2118v2" {
  route_table_id         = aws_route_table.private_kaushal2118v2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.kaushal2118v2.id
}

resource "aws_route_table_association" "private_1_kaushal2118v2" {
  subnet_id      = aws_subnet.private_1_kaushal2118v2.id
  route_table_id = aws_route_table.private_kaushal2118v2.id
}

resource "aws_route_table_association" "private_2_kaushal2118v2" {
  subnet_id      = aws_subnet.private_2_kaushal2118v2.id
  route_table_id = aws_route_table.private_kaushal2118v2.id
}

resource "aws_security_group" "eks_nodes_kaushal2118v2" {
  name        = "eks-nodes-kaushal2118v2"
  description = "Allow all traffic for EKS nodes"
  vpc_id      = aws_vpc.kaushal2118v2.id

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

resource "aws_security_group" "rds_kaushal2118v2" {
  name        = "rds-kaushal2118v2"
  description = "Allow MySQL access from EKS"
  vpc_id      = aws_vpc.kaushal2118v2.id

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

resource "aws_db_subnet_group" "kaushal2118v2" {
  name       = "db-subnet-group-kaushal2118v2"
  subnet_ids = [aws_subnet.private_1_kaushal2118v2.id, aws_subnet.private_2_kaushal2118v2.id]
}

resource "aws_db_instance" "kaushal2118v2" {
  identifier              = "kaushal-catalog-db-kaushal2118v2"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  skip_final_snapshot     = true
  publicly_accessible     = false
  db_name                 = "catalogdb"
  vpc_security_group_ids  = [aws_security_group.rds_kaushal2118v2.id]
  db_subnet_group_name    = aws_db_subnet_group.kaushal2118v2.name
}

resource "aws_dynamodb_table" "cart_kaushal2118v2" {
  name           = "cart-kaushal2118v2"
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
  cluster_name    = "kaushal-cluster-kaushal2118v2"
  cluster_version = "1.29"
  subnet_ids = [
    aws_subnet.private_1_kaushal2118v2.id,
    aws_subnet.private_2_kaushal2118v2.id
  ]
  vpc_id                        = aws_vpc.kaushal2118v2.id
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      name           = "ng-kaushal2118v2"
      instance_types = ["t2.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      ami_type       = "AL2_x86_64"
      key_name       = "practise1"
    }
  }
}
