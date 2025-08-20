terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project = "sample-vpc"
        Managed = "terraform"
      },
      var.tags
    )
  }
}

##### Data: AZs & AMIs #####

data "aws_availability_zones" "available" {
  state = "available"
}

# You asked to use this exact form to derive subnet CIDRs
locals {
  region    = var.region
  vpc_cidr  = var.vpc_cidr

  # Indexes: 0=a, 1=b, 2=c, 3=d (Based on 2025 Seoul)
  azs       = slice(data.aws_availability_zones.available.names, 0, 4)
  az_a      = local.azs[0]
  az_c      = local.azs[2]

  cidr_blocks = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]

  cidr_public_a  = local.cidr_blocks[0]
  cidr_private_a = local.cidr_blocks[1]
  cidr_public_c  = local.cidr_blocks[2]
  cidr_private_c = local.cidr_blocks[3]
}

# Amazon Linux 2023 (kernel 6.1) AMI
data "aws_ami" "al2023_k61" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

##### Networking #####

resource "aws_vpc" "this" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "sample-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "sample-igw"
  }
}

# Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.cidr_public_a
  availability_zone       = local.az_a
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.cidr_private_a
  availability_zone = local.az_a
  tags = {
    Name = "private-a"
    Tier = "private"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.cidr_public_c
  availability_zone       = local.az_c
  map_public_ip_on_launch = true
  tags = {
    Name = "public-c"
    Tier = "public"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.cidr_private_c
  availability_zone = local.az_c
  tags = {
    Name = "private-c"
    Tier = "private"
  }
}

# EIP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway in public subnet a
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-a"
  }
}

##### Route Tables #####

# Public route table to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "rt-public"
  }
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "public_c" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_c.id
}

# Private route table 1 (private-a to NAT)
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "rt-private1"
  }
}

resource "aws_route" "private1_default" {
  route_table_id         = aws_route_table.private1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a.id
}

resource "aws_route_table_association" "private_a" {
  route_table_id = aws_route_table.private1.id
  subnet_id      = aws_subnet.private_a.id
}

# Private route table 2 (private-c to NAT)
resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "rt-private2"
  }
}

resource "aws_route" "private2_default" {
  route_table_id         = aws_route_table.private2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a.id
}

resource "aws_route_table_association" "private_c" {
  route_table_id = aws_route_table.private2.id
  subnet_id      = aws_subnet.private_c.id
}

##### Security Groups #####

# ALB SG: allow 80 from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# Bastion SG: allow SSH from anywhere (per requirement)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

# Private EC2 SG: allow SSH and 8080 from anywhere
resource "aws_security_group" "private_ec2_sg" {
  name        = "private-ec2-sg"
  description = "Allow SSH & 8080"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP-Alt 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "private-ec2-sg" }
}


##### ALB + Target Group #####

resource "aws_lb" "alb" {
  name               = "sample-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  idle_timeout       = 60

  tags = { Name = "sample-alb" }
}

resource "aws_lb_target_group" "tg" {
  name     = "web-tg-8080"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = { Name = "web-tg-8080" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Attach Web01 to the target group on 8080
resource "aws_lb_target_group_attachment" "web01" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web01.id
  port             = 8080
}

##### EC2 Instances #####

# Bastion in public subnet a
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023_k61.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "bastion"
    Role = "bastion"
  }
}

# Web01 in private subnet c with python http.server on 8080
resource "aws_instance" "web01" {
  ami                    = data.aws_ami.al2023_k61.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_c.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              set -euxo pipefail
              dnf -y update
              dnf -y install python3

              cat >/var/www/index.html<<'EOP'
              <!doctype html>
              <html><body>
              <h1>Web01 (Python http.server @ 8080)</h1>
              <p>Hello from $(hostname) in ${local.az_c}</p>
              </body></html>
              EOP

              cat >/etc/systemd/system/pyhttp.service <<'EOS'
              [Unit]
              Description=Simple Python HTTP Server on 8080
              After=network-online.target

              [Service]
              Type=simple
              WorkingDirectory=/var
              ExecStart=/usr/bin/python3 -m http.server 8080 --directory /var/www
              Restart=always
              RestartSec=3

              [Install]
              WantedBy=multi-user.target
              EOS

              systemctl daemon-reload
              systemctl enable --now pyhttp.service
              EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "web01"
    Role = "web"
  }
}

