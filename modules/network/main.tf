# Criação da VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
    Environment = "production"
  }
}

# Subnet Pública para ALB (AZ-a)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_a
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-a"
    Type = "Public"
  }
}

# Subnet Pública para ALB (AZ-b)
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_b
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.project_name}-public-subnet-b"
    Type = "Public"
  }
}

# Subnet Privada para EC2 (AZ-a)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = var.availability_zone_a
  
  tags = {
    Name = "${var.project_name}-private-subnet-a"
    Type = "Private"
  }
}

# Subnet Privada para EC2 (AZ-b)
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = var.availability_zone_b
  
  tags = {
    Name = "${var.project_name}-private-subnet-b"
    Type = "Private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP para NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway para acesso à internet das subnets privadas
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.internet_gateway]
  
  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
}

# Route Table para subnets públicas
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  
  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

# Route Table para subnets privadas
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  
  tags = {
    Name = "${var.project_name}-private-route-table"
  }
}

# Associações das route tables com subnets públicas
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associações das route tables com subnets privadas
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_route_table.id
}
