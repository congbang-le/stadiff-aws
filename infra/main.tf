terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.10.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_default_vpc" "vpc" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "sg" {
  name        = "allow_access"
  description = "Allow Access inbound traffic"
  vpc_id      = aws_default_vpc.vpc.id

  ingress {
    description = "Access from home"
    from_port   = 22
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_access_from_home"
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = var.ssh_key
}

resource "aws_spot_instance_request" "vm" {
  ami                         = "ami-0650332016f0340e6"
  instance_type               = "g4dn.xlarge"
  key_name                    = "ssh-key"
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.sg.name}"]
  root_block_device {
    volume_size           = 100
    delete_on_termination = true
  }
  tags = {
    Name = "${var.prefix}-vm"
  }
}

