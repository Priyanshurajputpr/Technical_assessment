provider "aws" {
  region = "ap-southeast-2"
}

locals {
  name_prefix = "FirstName_Lastname"
  vpc_cidr    = "10.0.0.0/16"
  pub_sub_1   = "10.0.1.0/24"
  pub_sub_2   = "10.0.2.0/24"
  priv_sub_1  = "10.0.3.0/24"
  priv_sub_2  = "10.0.4.0/24"
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${local.name_prefix}_VPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${local.name_prefix}_IGW" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.pub_sub_1
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}_Public_Subnet_1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.pub_sub_2
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true
  tags = { Name = "${local.name_prefix}_Public_Subnet_2" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.priv_sub_1
  availability_zone = "ap-southeast-2a"
  tags = { Name = "${local.name_prefix}_Private_Subnet_1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.priv_sub_2
  availability_zone = "ap-southeast-2b"
  tags = { Name = "${local.name_prefix}_Private_Subnet_2" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = { Name = "${local.name_prefix}_NAT_EIP" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id
  tags = { Name = "${local.name_prefix}_NAT_Gateway" }
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${local.name_prefix}_Public_RT" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${local.name_prefix}_Private_RT" }
}

resource "aws_route_table_association" "pub_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "priv_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}