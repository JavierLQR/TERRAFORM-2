terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Indica de dónde obtener el proveedor de AWS (desde el registry oficial de HashiCorp)
      version = "~> 5.0"        # Usa la versión 5.x (mayor o igual a 5.0.0 pero menor a 6.0.0)
    }
    random = {
      source  = "hashicorp/random" # Indica de dónde obtener el proveedor 'random' (también de HashiCorp)
      version = "~> 3.0"           # Usa la versión 3.x (mayor o igual a 3.0.0 pero menor a 4.0.0)
    }
  }

  required_version = ">= 1.3.0" # Requiere que tengas Terraform 1.3.0 o superior instalado
}


variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
  default     = "my-bucket-unique-123"
}


provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Recurso para crear el bucket S3
resource "aws_s3_bucket" "mi_bucket_s3" {
  bucket = var.bucket_name
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}

# Configuración de ACL para el bucket
resource "aws_s3_bucket_ownership_controls" "mi_bucket_ownership_controls" {
  bucket = aws_s3_bucket.mi_bucket_s3.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Configuración de ACL para el bucket
resource "aws_s3_bucket_public_access_block" "mi_bucket_public_access_block" {
  bucket = aws_s3_bucket.mi_bucket_s3.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Configuración de ACL para el bucket
resource "aws_s3_bucket_acl" "mi_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.mi_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.mi_bucket_public_access_block
  ]

  bucket = aws_s3_bucket.mi_bucket_s3.id
  acl    = "public-read"

}

output "name_bucket" {
  value       = aws_s3_bucket.mi_bucket_s3.id
  description = "Name of the bucket"
  sensitive   = false
}
