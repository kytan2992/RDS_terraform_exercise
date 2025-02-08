data "aws_vpc" "vpc" {
  id = var.vpc
}

data "aws_subnet" "public_subnet" {
  id = var.public_subnet
}

data "aws_subnet" "private_subnet" {
  id = var.private_subnet
}

data "aws_ami" "ami_linux" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}