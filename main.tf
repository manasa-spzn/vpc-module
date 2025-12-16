#create vpc
resource "aws_vpc" "my_vpc" {
  region     = var.region
  cidr_block = var.vpc_cidr
  tags = {
    Name = "my-vpc"
  }
}

#dynamically fetch available availability zones in the specified region
data "aws_availability_zones" "available_azs" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}


#create two public subnets in the vpc, each in a different az
resource "aws_subnet" "public_subnet_1" {
  region                  = var.region
  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = data.aws_availability_zones.available_azs.names[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }

}
resource "aws_subnet" "public_subnet_2" {
  region                  = var.region
  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = data.aws_availability_zones.available_azs.names[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

#create an internet gateway for the public subnets
resource "aws_internet_gateway" "my_igw" {
  region = var.region
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}

#create a route table for the public subnets
resource "aws_route_table" "public_rt" {
  region = var.region
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

#associate the public subnets with the route table
resource "aws_route_table_association" "public_rt_assoc_1" {
  region         = var.region
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_rt_assoc_2" {
  region         = var.region
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}


#create two private subnets in the vpc, each in a different az
resource "aws_subnet" "private_subnet_1" {
  region                  = var.region
  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = data.aws_availability_zones.available_azs.names[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 3)
  map_public_ip_on_launch = false
  enable_resource_name_dns_a_record_on_launch = true 
  private_dns_hostname_type_on_launch        = "ip-name" 
  tags = {
    Name = "private-subnet-1"
  }
}
resource "aws_subnet" "private_subnet_2" {
  region                  = var.region
  vpc_id                  = aws_vpc.my_vpc.id
  availability_zone       = data.aws_availability_zones.available_azs.names[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 4)
  map_public_ip_on_launch = false
  enable_resource_name_dns_a_record_on_launch = true 
  private_dns_hostname_type_on_launch        = "ip-name" 
  tags = {
    Name = "private-subnet-2"
  }
}

#create an elastic IP for the nat gateway
resource "aws_eip" "nat_eip" {
  region = var.region
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

#create a nat gateway
resource "aws_nat_gateway" "my_ngw" {
  region            = var.region
  subnet_id         = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip.id
  tags = {
    Name = "nat-gw"
  }
}

#create a route table for the private subnets
resource "aws_route_table" "private_rt" {
  region = var.region
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_ngw.id
  }
  tags = {
    Name = "private-rt"
  }
}

#associate the private subnets with the route table
resource "aws_route_table_association" "private_rt_assoc_1" {
  region         = var.region
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_rt_assoc_2" {
  region         = var.region
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
