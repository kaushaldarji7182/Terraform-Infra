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

resource "aws_vpc" "kaushal2118v3" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "kaushal2118v3" {
  vpc_id = aws_vpc.kaushal2118v3.id
}

resource "aws_subnet" "public_1_kaushal2118v3" {
  vpc_id                  = aws_vpc.kaushal2118v3.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_2_kaushal2118v3" {
  vpc_id                  = aws_vpc.kaushal2118v3.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_1_kaushal2118v3" {
  vpc_id            = aws_vpc.kaushal2118v3.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "private_2_kaushal2118v3" {
  vpc_id            = aws_vpc.kaushal2118v3.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_eip" "nat_kaushal2118v3" {
  domain = "vpc"
}

resource "aws_nat_gateway" "kaushal2118v3" {
  allocation_id = aws_eip.nat_kaushal2118v3.id
  subnet_id     = aws_subnet.public_1_kaushal2118v3.id
  depends_on    = [aws_internet_gateway.kaushal2118v3]
}

resource "aws_route_table" "public_kaushal2118v3" {
  vpc_id = aws_vpc.kaushal2118v3.id
}

resource "aws_route" "public_route_kaushal2118v3" {
  route_table_id         = aws_route_table.public_kaushal2118v3.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kaushal2118v3.id
}

resource "aws_route_table_association" "public_1_kaushal2118v3" {
  subnet_id      = aws_subnet.public_1_kaushal2118v3.id
  route_table_id = aws_route_table.public_kaushal2118v3.id
}

resource "aws_route_table_association" "public_2_kaushal2118v3" {
  subnet_id      = aws_subnet.public_2_kaushal2118v3.id
  route_table_id = aws_route_table.public_kaushal2118v3.id
}

resource "aws_route_table" "private_kaushal2118v3" {
  vpc_id = aws_vpc.kaushal2118v3.id
}

resource "aws_route" "private_kaushal2118v3" {
  route_table_id         = aws_route_table.private_kaushal2118v3.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.kaushal2118v3.id
}

resource "aws_route_table_association" "private_1_kaushal2118v3" {
  subnet_id      = aws_subnet.private_1_kaushal2118v3.id
  route_table_id = aws_route_table.private_kaushal2118v3.id
}

resource "aws_route_table_association" "private_2_kaushal2118v3" {
  subnet_id      = aws_subnet.private_2_kaushal2118v3.id
  route_table_id = aws_route_table.private_kaushal2118v3.id
}

resource "aws_security_group" "eks_nodes_kaushal2118v3" {
  name        = "eks-nodes-kaushal2118v3"
  description = "Allow all traffic for EKS nodes"
  vpc_id      = aws_vpc.kaushal2118v3.id

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

resource "aws_db_subnet_group" "rds_kaushal2118v3" {
  name       = "kaushal-db-subnet-group-kaushal2118v3"
  subnet_ids = [aws_subnet.private_1_kaushal2118v3.id, aws_subnet.private_2_kaushal2118v3.id]
}

resource "aws_db_instance" "kaushal2118v3" {
  identifier              = "kaushal-catalog-db-kaushal2118v3"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  username                = "admin"
  password                = "admin1234"
  allocated_storage       = 20
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.rds_kaushal2118v3.name
  vpc_security_group_ids  = [aws_security_group.eks_nodes_kaushal2118v3.id]
  publicly_accessible     = false
  backup_retention_period = 0
  db_name                 = "catalogdb"
}

resource "aws_dynamodb_table" "cart_kaushal2118v3" {
  name           = "cart-kaushal2118v3"
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
  cluster_name    = "kaushal-cluster-kaushal2118v3"
  cluster_version = "1.29"
  vpc_id          = aws_vpc.kaushal2118v3.id
  subnet_ids      = [
    aws_subnet.private_1_kaushal2118v3.id,
    aws_subnet.private_2_kaushal2118v3.id
  ]
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      max_size       = 3
      min_size       = 1
      instance_types = ["t2.medium"]
      name           = "kaushal-node-group-kaushal2118v3"
    }
  }
}
