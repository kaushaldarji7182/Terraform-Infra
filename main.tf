terraform {
  backend "s3" {
    bucket = "kaushal2118terraformfinalbucket"
    key    = "terraform.tfstate"
    region = "us-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "kaushal2118v3" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kaushal-vpc-kaushal2118v3"
  }
}

resource "aws_subnet" "public_kaushal2118v3" {
  count             = 2
  vpc_id            = aws_vpc.kaushal2118v3.id
  cidr_block        = cidrsubnet("10.0.1.0/24", 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = ["us-west-1a", "us-west-1b"][count.index]
  tags = {
    Name = "public-subnet-kaushal2118v3-${count.index}"
  }
}

resource "aws_subnet" "private_kaushal2118v3" {
  count             = 2
  vpc_id            = aws_vpc.kaushal2118v3.id
  cidr_block        = cidrsubnet("10.0.2.0/24", 4, count.index)
  availability_zone = ["us-west-1a", "us-west-1b"][count.index]
  tags = {
    Name = "private-subnet-kaushal2118v3-${count.index}"
  }
}

resource "aws_internet_gateway" "kaushal2118v3" {
  vpc_id = aws_vpc.kaushal2118v3.id
  tags = {
    Name = "igw-kaushal2118v3"
  }
}

resource "aws_route_table" "public_kaushal2118v3" {
  vpc_id = aws_vpc.kaushal2118v3.id
  tags = {
    Name = "public-rt-kaushal2118v3"
  }
}

resource "aws_route" "internet_kaushal2118v3" {
  route_table_id         = aws_route_table.public_kaushal2118v3.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kaushal2118v3.id
}

resource "aws_route_table_association" "public_kaushal2118v3" {
  count          = 2
  subnet_id      = aws_subnet.public_kaushal2118v3[count.index].id
  route_table_id = aws_route_table.public_kaushal2118v3.id
}

resource "aws_security_group" "rds_sg_kaushal2118v3" {
  name        = "rds-sg-kaushal2118v3"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.kaushal2118v3.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-kaushal2118v3"
  }
}

resource "aws_db_subnet_group" "kaushal2118v3" {
  name       = "db-subnet-group-kaushal2118v3"
  subnet_ids = aws_subnet.private_kaushal2118v3[*].id

  tags = {
    Name = "DB subnet group kaushal2118v3"
  }
}

resource "aws_db_instance" "kaushal2118v3" {
  identifier             = "kaushal-catalog-db-kaushal2118v3"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Admin12345!"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.kaushal2118v3.name
  vpc_security_group_ids = [aws_security_group.rds_sg_kaushal2118v3.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "kaushal-rds-kaushal2118v3"
  }
}

resource "aws_dynamodb_table" "cart_kaushal2118v3" {
  name         = "cart-kaushal2118v3"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "cart-table-kaushal2118v3"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.37.1"
  cluster_name    = "kaushal-cluster-kaushal2118v3"
  cluster_version = "1.29"
  subnet_ids      = aws_subnet.public_kaushal2118v3[*].id
  vpc_id          = aws_vpc.kaushal2118v3.id

  eks_managed_node_groups = {
    default = {
      desired_size = 1
      max_size     = 2
      min_size     = 1

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
    Project     = "kaushal2118v3"
  }
}
