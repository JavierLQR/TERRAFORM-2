# variable for region
variable "region" {
  type    = string
  default = "us-east-1"
}

# Variable for bucket name
variable "bucket_name" {
  type    = string
  default = "my-tf-test-bucket"
}
# Configure the AWS Provider
provider "aws" {
  region = var.region

}

# Create S3 bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

}
# Block public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.app_bucket.id

}

