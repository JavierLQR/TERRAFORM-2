variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
  default     = "my_bucket_unique"
}


provider "aws" {
  region = "us-east-1"
}

# Recurso para crear el bucket S3
resource "aws_s3_bucket" "mi_bucket" {
  bucket = var.bucket_name
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}

# Configuración de ACL para el bucket
resource "aws_s3_bucket_ownership_controls" "mi_bucket_ownership_controls" {
  bucket = aws_s3_bucket.mi_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Configuración de ACL para el bucket
resource "aws_s3_bucket_public_access_block" "mi_bucket_public_access_block" {
  bucket = aws_s3_bucket.mi_bucket.id

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

  bucket = aws_s3_bucket.mi_bucket.id
  acl    = "public-read"

}
