# variables.tf
variable "region" {
  default = "us-east-1"
}

variable "my_ip" {
  default     = "179.1.149.114"
  description = "My IP address"
  type        = string
}

variable "env" {
  description = "Environment (dev or prod)"
  default     = "deve"
  type        = string
}

# main.tf
provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = var.env == "dev" ? true : false
}

resource "aws_db_parameter_group" "rds_pg" {
  name   = "${var.env}-rds-pg"
  family = "postgres15" # Familia para PostgreSQL 15.3

  parameter {
    name  = "rds.force_ssl"
    value = var.env == "prod" ? "1" : "0" # Forzar SSL en prod
  }
}
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.env}-rds"

  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.env == "prod" ? "db.t3.medium" : "db.t3.micro"
  allocated_storage = var.env == "prod" ? 100 : 20

  db_name                 = "${var.env}db"
  username                = "dbuser"
  password                = aws_secretsmanager_secret_version.db_password.secret_string
  port                    = 5432
  family                  = "postgres15"
  vpc_security_group_ids  = [module.security_group.security_group_id]
  subnet_ids              = module.vpc.private_subnets
  multi_az                = var.env == "prod" ? true : false
  backup_retention_period = var.env == "prod" ? 7 : 1

  # Vincular el grupo de parámetros
  parameter_group_name = aws_db_parameter_group.rds_pg.name
  depends_on           = [module.security_group]
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.env}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "${var.my_ip}/32"
    }
  ]

  depends_on = [module.vpc]
}


resource "aws_secretsmanager_secret" "db_password_test" {
  name = "test1/rds/password"

}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password_test.id
  secret_string = random_password.db_password.result
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}


output "rds_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "RDS instance endpoint"

}

output "password_aws_secret" {
  value       = aws_secretsmanager_secret.db_password_test.id
  description = "ARN del secret"

}


output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}
