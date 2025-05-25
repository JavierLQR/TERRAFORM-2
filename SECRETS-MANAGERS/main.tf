

variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Region must be either 'us-east-1' or 'us-west-2'."
  }
}


provider "aws" {
  region = var.region

}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  upper            = true


}


resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.env}-db-password"
  description = "RDS database password"

  tags = {
    Environment = var.env
  }

}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsondecode(
  )["password"]
}
