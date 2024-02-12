provider "aws"{
  region = "us-east-1"
}

data "aws_availability_zones" "all" {}

resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Demo VPC"
  }
}

# Creating Internet Gateway
resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

# Creating Public First Subnet
resource "aws_subnet" "my_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block             = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet-1"
  }
}

resource "aws_subnet" "my_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block             = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet-2"
  }
}


# Creating Route Table for Public Subnet 1
resource "aws_route_table" "rt1" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_gateway.id
    }

    tags = {
        Name = "Public Route Table1"
    }
}

resource "aws_route_table_association" "rt_associate_public_1" {
    subnet_id = aws_subnet.my_subnet1.id
    route_table_id = aws_route_table.rt1.id
}

#creating Route table for public subnet 2
resource "aws_route_table" "rt2" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_gateway.id
    }

    tags = {
        Name = "Public Route Table2"
    }
}

resource "aws_route_table_association" "rt_associate_public_2" {
    subnet_id = aws_subnet.my_subnet2.id
    route_table_id = aws_route_table.rt2.id
}

# Create security groups for ec2 instances in public subnet
resource "aws_security_group" "my_sg" {

  vpc_id      = aws_vpc.my_vpc.id

  # Inbound Rules
  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  # Internet access to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating EC2 instance in Public Subnet
resource "aws_instance" "my_instance1" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.micro"
  count = 1
  key_name = "dev-ops"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id = aws_subnet.my_subnet1.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              echo '<html><body><h1>HeLLo</h1></html>' > index.html
              nohup busybox httpd -f -p "${8080}" &
              EOF

  tags = {
    Name = "Public Instance1"
  }
}

# Creating EC2 instance in Public Subnet2 i.e 3
resource "aws_instance" "my_instance2" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.micro"
  count = 1
  key_name = "dev-ops"
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id = aws_subnet.my_subnet2.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              echo '<html><body><h1>HeLLLLLLOOOOO</h1> </html>' > index.html
              nohup busybox httpd -f -p "${8080}" &
              EOF

  tags = {
    Name = "Public Instance2"
  }
}

resource "aws_security_group" "elb" {
  name = "adam-example-elb"

  # Allow all outbound (-1)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT'S APPLIED TO EACH EC2 INSTANCE IN THE ASG
# ------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name = "adam-example-instance-elb"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------------------------------------------------------
# CREATE AN APPLICATION ELB TO ROUTE TRAFFIC ACROSS THE AUTO SCALING GROUP
# ------------------------------------------------------------------------

resource "aws_elb" "example" {
  name               = "adam-elb-example"
  security_groups    = [aws_security_group.elb.id]
  availability_zones = data.aws_availability_zones.all.names

  health_check {
    target              = "HTTP:8080/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }
}

# -----------------------------------------------------------------------
# CREATE A LAUNCH CONFIGURATION THAT DEFINES EACH EC2 INSTANCE IN THE ASG
# -----------------------------------------------------------------------

resource "aws_launch_configuration" "example1" {
  name = "adam-example-launchconfig2"
  # Ubuntu Server 18.04 LTS (HVM), SSD Volume Type in ap-south-01
  image_id        = "ami-06aa3f7caf3a30282"
  instance_type   = "t2.medium"
  security_groups = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo '<html><body><h1>Hello </h1></html>' > index.html
              nohup busybox httpd -f -p "${8080}" &
              EOF

  # Whenever using a launch configuration with an auto scaling group, you must set below
  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------
# CREATE THE AUTO SCALING GROUP
# -----------------------------

resource "aws_autoscaling_group" "example" {
  name = "adam-example-asg"
  launch_configuration = aws_launch_configuration.example1.id
  availability_zones   = data.aws_availability_zones.all.names

  min_size = 2
  max_size = 4

  load_balancers    = [aws_elb.example.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "ADAM-ASG-PROJECT"
    propagate_at_launch = true
  }
}
