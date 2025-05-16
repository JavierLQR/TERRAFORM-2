# provider "aws" {
#   region = "us-east-1"

# }
# data "aws_ami" "amazon_linux_2" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*-x86_64"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   tags = {
#     Name     = "Amazon Linux 2 AMI"
#     NODE_ENV = var.environment
#   }

# }

# resource "aws_instance" "ngnix-server" {
#   instance_type = var.type_instance
#   ami           = data.aws_ami.amazon_linux_2.id

#   user_data = <<-EOF
#               #!/bin/bash
#               dnf update -y
#               dnf install -y nginx
#               systemctl enable nginx
#               systemctl start nginx

#               dnf install -y docker git -y
#               systemctl enable docker
#               systemctl start docker



#               # Instalar AWS CLI (si no está disponible por defecto)
#               dnf install -y awscli

#               # Autenticación con ECR
#               aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 222634373780.dkr.ecr.us-east-1.amazonaws.com

#               # Descargar imagen desde ECR
#               docker pull 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v1

#               # Ejecutar contenedor NestJS
#               docker run -d --restart always -p 3000:3000 --name nestjs-app 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v1

#               EOF

#   key_name = aws_key_pair.deployer.key_name

#   vpc_security_group_ids = [aws_security_group.nginx_security_group.id]

#   tags = {
#     Name     = "Nginx Server"
#     NODE_ENV = var.environment
#   }
# }

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

# ✅ 1. Crear un rol IAM para que la instancia EC2 pueda asumirlo
resource "aws_iam_role" "ec2_ecr_access" {
  name = "ec2-ecr-access-role" # Nombre del rol

  # Política de confianza: define quién puede asumir este rol (en este caso, EC2)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole", # Acción que permite asumir el rol
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com" # Este rol puede ser asumido por instancias EC2
      }
    }]
  })
}
# ✅ 2. Asignar una política al rol para permitirle acceder a ECR
resource "aws_iam_role_policy" "ecr_policy" {
  name = "ecr-access"                   # Nombre de la política
  role = aws_iam_role.ec2_ecr_access.id # Asocia la política al rol creado arriba

  # Política en formato JSON que define los permisos
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",       # Obtener token para autenticarse en ECR
          "ecr:BatchCheckLayerAvailability", # Verificar disponibilidad de capas de imagen
          "ecr:GetDownloadUrlForLayer",      # Obtener URLs para descargar capas
          "ecr:BatchGetImage"                # Obtener la imagen del contenedor desde ECR
        ],
        Resource = "*" # Aplica a todos los repositorios ECR del usuario
      }
    ]
  })
}

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

              # Pull y ejecutar la imagen
              docker pull 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v1
              docker run -d --restart always -p 3000:3000 --name nestjs-app 222634373780.dkr.ecr.us-east-1.amazonaws.com/nest-terraform:v1
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


