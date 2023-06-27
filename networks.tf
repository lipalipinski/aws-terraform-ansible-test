# create VPC in master region
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-jenkins"
  }
}

# create VPC in worker region
resource "aws_vpc" "vpc_worker" {
  provider             = aws.region-worker
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "worker-vpc-jenkins"
  }
}

# create IGW in master region
resource "aws_internet_gateway" "igw-master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

# create IGW in worker region
resource "aws_internet_gateway" "igw-worker" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id
}

# get all AZ's in master VPC 
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# create subnet #1 in master VPC
resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.10.0/24"
}

# create subnet #2 in master VPC
resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.20.0/24"
}

# create subnet in worker VPC
resource "aws_subnet" "subnet_1-worker" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_worker.id
  cidr_block = "10.10.10.0/24"
}

# init peering connection requuest from master region
resource "aws_vpc_peering_connection" "master-worker" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_worker.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
  tags = {
    Name = "master-worker"
  }
}

# accept VPC peering request in worker region from master region
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.master-worker.id
  auto_accept               = true
}

# create route table in master vpc
resource "aws_route_table" "masterRT" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-master.id
  }
  route {
    cidr_block                = "10.10.10.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.master-worker.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "master region RT"
  }
}

# overwrite default RT for master VPC
resource "aws_main_route_table_association" "set-master-rt" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.masterRT.id
}

# create route table in worker vpc
resource "aws_route_table" "workerRT" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_worker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-worker.id
  }
  route {
    cidr_block                = "10.0.10.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.master-worker.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "worker region RT"
  }
}

# overwrite default RT for worker VPC
resource "aws_main_route_table_association" "set-worker-rt" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_worker.id
  route_table_id = aws_route_table.workerRT.id
}