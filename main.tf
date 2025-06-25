terraform {
  required_version = ">= 1.3"

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

# ---------------- VPC ----------------
resource "aws_vpc" "kaushal2118" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "kaushal2118-vpc"
  }
}

resource "aws_internet_gateway" "kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
  tags = {
    Name = "kaushal2118-igw"
  }
}

# ---------------- Subnets ----------------
resource "aws_subnet" "public_1_kaushal2118" {
  vpc_id                  = aws_vpc.kaushal2118.id
  cidr_block              = var.public_subnet_1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "kaushal2118-public-subnet-1"
  }
}

resource "aws_subnet" "public_2_kaushal2118" {
  vpc_id                  = aws_vpc.kaushal2118.id
  cidr_block              = var.public_subnet_2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "kaushal2118-public-subnet-2"
  }
}

resource "aws_subnet" "private_1_kaushal2118" {
  vpc_id            = aws_vpc.kaushal2118.id
  cidr_block        = var.private_subnet_1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "kaushal2118-private-subnet-1"
  }
}

resource "aws_subnet" "private_2_kaushal2118" {
  vpc_id            = aws_vpc.kaushal2118.id
  cidr_block        = var.private_subnet_2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "kaushal2118-private-subnet-2"
  }
}

# ---------------- Routing ----------------
resource "aws_eip" "nat_kaushal2118" {
  domain = "vpc"
}

resource "aws_nat_gateway" "kaushal2118" {
  allocation_id = aws_eip.nat_kaushal2118.id
  subnet_id     = aws_subnet.public_1_kaushal2118.id
  depends_on    = [aws_internet_gateway.kaushal2118]
  tags = {
    Name = "kaushal2118-nat"
  }
}

resource "aws_route_table" "public_kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
}

resource "aws_route" "public_route_kaushal2118" {
  route_table_id         = aws_route_table.public_kaushal2118.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kaushal2118.id
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1_kaushal2118.id
  route_table_id = aws_route_table.public_kaushal2118.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2_kaushal2118.id
  route_table_id = aws_route_table.public_kaushal2118.id
}

resource "aws_route_table" "private_kaushal2118" {
  vpc_id = aws_vpc.kaushal2118.id
}

resource "aws_route" "private_route_kaushal2118" {
  route_table_id         = aws_route_table.private_kaushal2118.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.kaushal2118.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1_kaushal2118.id
  route_table_id = aws_route_table.private_kaushal2118.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2_kaushal2118.id
  route_table_id = aws_route_table.private_kaushal2118.id
}
