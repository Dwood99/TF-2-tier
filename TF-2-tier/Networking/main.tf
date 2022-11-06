#--- Networking main.tf ---#

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "Main VPC"
  }
}

# Subnets
resource "aws_subnet" "public-1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.cidr_block
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

# Route table
resource "aws_route_table" "main_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Main-Route-Table"
  }
}

# Route table associations
resource "aws_route_table_association" "route_association_1" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.main_route.id
}

resource "aws_route_table_association" "route_association_2" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.main_route.id
}