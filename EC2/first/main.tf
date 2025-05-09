provider "aws" {
  region = "us-east-1"

}



data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  tags = {
    Name     = "Amazon Linux 2 AMI"
    NODE_ENV = var.environment
  }

}

resource "aws_instance" "ngnix-server" {
  instance_type = var.type_instance
  ami           = data.aws_ami.amazon_linux_2.id

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = {
    Name     = "Nginx Server"
    NODE_ENV = var.environment
  }
}

resource "aws_security_group" "nginx_security_group" {
  description = "Security group for nginx server"
  name        = var.server_name

  ingress {
    description = "Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Port 0"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = var.server_name
    NODE_ENV = var.environment
  }
}
