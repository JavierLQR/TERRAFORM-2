
provider "aws" {
  region = "us-east-1"
}

# Variables
variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "type_instance" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}

variable "server_name" {
  description = "Server name"
  type        = string
  default     = "nginx-server"
}

# Obtener la última AMI Amazon Linux 2023
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
}

# IAM Role para ECR acceso
resource "aws_iam_role" "ec2_ecr_access" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
# IAM Policy
resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr-access"
  role = aws_iam_role.ec2_ecr_access.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_access.name
}

# Security Group
resource "aws_security_group" "nginx_security_group" {
  name        = var.server_name
  description = "Allow SSH and HTTP"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "SSH"
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

  tags = {
    Name     = var.server_name
    NODE_ENV = var.environment
  }
}

# Key Pair (preexistente)
resource "aws_key_pair" "deployer" {
  key_name   = "${var.server_name}.key"
  public_key = file("${var.server_name}.key.pub")
}

# EC2 Instance
resource "aws_instance" "ngnix-server" {
  instance_type = var.type_instance
  ami           = data.aws_ami.amazon_linux_2.id

  iam_instance_profile   = aws_iam_instance_profile.ec2_ecr_profile.name
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.nginx_security_group.id]

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx docker awscli git
              systemctl enable nginx
              systemctl start nginx
              systemctl enable docker
              systemctl start docker

              # Login a ECR
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 222634373780.dkr.ecr.us-east-1.amazonaws.com

              # Detener y eliminar contenedor anterior si existe
              docker stop nestjs-app || true
              docker rm nestjs-app || true

              # Pull y ejecutar la nueva imagen
              docker pull 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v2
              docker run -d --restart always -p 3000:3000 --name nestjs-app 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v2
              EOF


  tags = {
    Name     = "Nginx Server"
    NODE_ENV = var.environment
  }
}

# Outputs
output "public_ip" {
  description = "Public IP"
  value       = aws_instance.ngnix-server.public_ip
}

output "public_dns" {
  description = "Public DNS"
  value       = aws_instance.ngnix-server.public_dns
}


