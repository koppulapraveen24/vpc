#provider "aws" {
#  region = var.region
#}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet-cidr-a
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet-cidr-b
  availability_zone = "${var.region}b"
}

resource "aws_subnet" "subnet-c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet-cidr-c
  availability_zone = "${var.region}c"
}

resource "aws_route_table" "subnet-route-table" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "subnet-route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.subnet-route-table.id
}

resource "aws_route_table_association" "subnet-a-route-table-association" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.subnet-route-table.id
}

resource "aws_route_table_association" "subnet-b-route-table-association" {
  subnet_id      = aws_subnet.subnet-b.id
  route_table_id = aws_route_table.subnet-route-table.id
}

resource "aws_route_table_association" "subnet-c-route-table-association" {
  subnet_id      = aws_subnet.subnet-c.id
  route_table_id = aws_route_table.subnet-route-table.id
}



resource "aws_instance" "instance" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [ aws_security_group.security-group.id ]
  subnet_id                   = aws_subnet.subnet-a.id
  associate_public_ip_address = true
  user_data                   = <<EOF
#!/bin/sh
yum install -y nginx
service nginx start
EOF
}

resource "aws_security_group" "security-group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

output "nginx_domain" {
  value = aws_instance.instance.public_dns
}

####################################################
### Creating an private subnet for security
## Create an EIP for natgateway 
resource "aws_eip" "nat_eip" {
  domain        = "vpc"
  depends_on = [aws_internet_gateway.igw]
  }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet-a.id
  lifecycle {
  prevent_destroy = false
  create_before_destroy = false
  }
  tags = {
    Name = "private-Nat-Gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# create Route Table and Add Private Route
# terraform aws create route table
resource "aws_route_table" "private-route-table" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags       = {
    Name     = "private Route Table"
  }
}

# Associate private subnet to "private Route Table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "private_subnet-route-table-association" {
  subnet_id           = aws_subnet.private_subnet.id
  route_table_id      = aws_route_table.private-route-table.id
}
# Create Private Subnet
# terraform aws create subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.private_subnet
  availability_zone        = "us-east-1a"
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "private_subnet"
  }
}


###3. We are proceeding with autoscaling so the it would be taking care of instance even if we don't take care of it ##
### here we are using the asme ami id so that it doesn't creare any issue

resource "aws_launch_configuration" "instance" {
  name_prefix   = "instance-lc"
  image_id      = var.ami_id
  instance_type = "t2.small"
  user_data                   = <<EOF
#!/bin/sh
service nginx start
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "instance" {
  name                 = "asg"
  launch_configuration = aws_launch_configuration.conf.id
  min_size             = 1
  max_size             = 1
  availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"] # availability zone might be changing based on regions
  desired_capacity     = 1

  lifecycle {
    create_before_destroy = true
  }
}
