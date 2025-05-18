
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "RDS master username"

  default = "admin"
}

variable "db_password" {
  description = "RDS master password"
  sensitive   = true
  default     = "YourSecurePassword123"
}


variable "db_name" {
  description = "Database name"
  default     = "mydb"
}
provider "aws" {
  region = "us-east-1"
}




module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "rds-vpc"
  cidr = var.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Environment = "dev" }
}


resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = { Environment = "dev" }
}

resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "PostgreSQL from VPN"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block] # Fixed to the VPC's CIDR block
  }

  egress {
    from_port = 0

    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = "dev" }
}

resource "aws_db_instance" "default" {

  identifier             = "dev-rds"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = { Environment = "dev" }

}



resource "aws_security_group" "vpn" {
  name        = "vpn-security-group"
  description = "Security group for VPN access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_acm_certificate" "server" {
  private_key       = file("server.key")
  certificate_body  = file("server.crt")
  certificate_chain = file("ca.crt")

  tags = {
    Environment = "dev"
  }
}

resource "aws_acm_certificate" "client" {
  private_key       = file("client.key")
  certificate_body  = file("client.crt")
  certificate_chain = file("ca.crt")

  tags = {
    Environment = "dev"
  }
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "Client VPN for RDS access"
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = "10.1.0.0/22"
  vpc_id                 = module.vpc.vpc_id
  security_group_ids     = [aws_security_group.vpn.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.client.arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Environment = "dev"
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_assoc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = module.vpc.private_subnets[0]
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = module.vpc.vpc_cidr_block
  authorize_all_groups   = true
}


output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.default.endpoint
}

output "vpn_endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.vpn.id
}





# variable "region" {
#   default = "us-east-1"
# }

# variable "db_username" {
#   default = "admin"
# }

# variable "db_password" {
#   default = "mysecretpassword"
# }

# variable "db_name" {
#   default = "mydatabase"
# }
# provider "aws" {
#   region = var.region
# }

# # 1. VPC
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }

# # 2. Subnet privada
# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
# }

# # 3. Internet Gateway (necesario para VPN si hay split-tunnel)
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id
# }

# # 4. Route Table
# resource "aws_route_table" "rt" {
#   vpc_id = aws_vpc.main.id
# }

# resource "aws_route_table_association" "rt_assoc" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.rt.id
# }

# # 5. Security Group para RDS
# resource "aws_security_group" "rds_sg" {
#   name   = "rds_sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 5432
#     to_port     = 5432
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/8"] # VPN CIDR
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # 6. Subnet Group para RDS
# resource "aws_db_subnet_group" "db_subnet_group" {
#   name       = "main-subnet-group"
#   subnet_ids = [aws_subnet.private.id]
# }

# # 7. RDS PostgreSQL
# resource "aws_db_instance" "postgres" {
#   identifier             = "my-postgres-db"
#   allocated_storage      = 20
#   engine                 = "postgres"
#   engine_version         = "15.2"
#   instance_class         = "db.t3.micro"
#   db_name                = var.db_name
#   username               = var.db_username
#   password               = var.db_password
#   db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   skip_final_snapshot    = true
#   publicly_accessible    = false
# }

# # 8. Cargar Certificados a ACM
# resource "aws_acm_certificate" "vpn_server" {
#   private_key       = file("vpn_cert/server.key")
#   certificate_body  = file("vpn_cert/server.crt")
#   certificate_chain = file("vpn_cert/ca.crt")
# }

# resource "aws_acm_certificate" "vpn_client" {
#   private_key       = file("vpn_cert/client.key")
#   certificate_body  = file("vpn_cert/client.crt")
#   certificate_chain = file("vpn_cert/ca.crt")
# }

# # 9. VPN Client Endpoint
# resource "aws_ec2_client_vpn_endpoint" "vpn" {
#   description            = "VPN para acceso a RDS"
#   client_cidr_block      = "10.200.0.0/16"
#   server_certificate_arn = aws_acm_certificate.vpn_server.arn
#   authentication_options {
#     type                       = "certificate-authentication"
#     root_certificate_chain_arn = aws_acm_certificate.vpn_client.arn
#   }
#   connection_log_options {
#     enabled = false
#   }
#   dns_servers        = ["8.8.8.8"]
#   split_tunnel       = true
#   transport_protocol = "udp"
#   vpc_id             = aws_vpc.main.id
# }

# # 10. Asociación VPN con Subnet
# resource "aws_ec2_client_vpn_network_association" "vpn_assoc" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
#   subnet_id              = aws_subnet.private.id
# }

# # 11. Autorización a RDS
# resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
#   target_network_cidr    = aws_vpc.main.cidr_block
#   authorize_all_groups   = true
# }

# output "rds_endpoint" {
#   value = aws_db_instance.postgres.endpoint
# }

# output "vpn_endpoint" {
#   value = aws_ec2_client_vpn_endpoint.vpn.dns_name
# }
