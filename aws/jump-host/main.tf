terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}
data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
resource "aws_key_pair" "jumphost_kp" {
    key_name = "jumphost_kp"
    public_key = file("./aws/jump-host/jumphost_kp.pub")
}
resource "aws_security_group" "publicssh" {
  # Ensure that SG is unique, so that this module can be used multiple times within a single VPC
  name = "public_access_ssh_jumphost"
  description = "Confluent Cloud Private Link minimal security group for jumphost"
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    owner       = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "jumphost" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.jumphost_kp.key_name

  vpc_security_group_ids = [aws_security_group.publicssh.id]

  subnet_id = var.subnet_id

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run confluentinc/cp-kafkacat /bin/sh -c "sleep 36500d"
              EOF

  tags = {
    Name = "EC2-Docker-kafkacat"
    owner = var.owner
  }
}
# Elastic-IP (eip) for JumpHost
resource "aws_eip" "jump_eip" {
  domain        = "vpc"
  instance      = aws_instance.jumphost.id
  tags = {
    Name        = "${var.env_prefix}-jump-ip"
    Owner       = var.owner
  }
}
