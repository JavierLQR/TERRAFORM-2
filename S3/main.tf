variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
  default     = "my_bucket_unique"
}


provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "mi_bucket" {
  bucket = var.bucket_name
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}
