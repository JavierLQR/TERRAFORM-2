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

  key_name = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.nginx_security_group.id]

  tags = {
    Name     = "Nginx Server"
    NODE_ENV = var.environment
  }
}



