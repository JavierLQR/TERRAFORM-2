
# ES UNA PRACTICA DE TERRAFORM RECOMMENDED
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


# Recurso para generar un ID aleatorio
resource "random_id" "bucket_suffix" {
  byte_length = 2
}

# Recurso para crear el bucket S3
resource "aws_s3_bucket" "mi_bucket_s3" {
  bucket = "${var.bucket_name}-${random_id.bucket_suffix.hex}"
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}

# Recurso para vaciar el bucket
resource "null_resource" "empty_bucket" {
  provisioner "local-exec" {
    command = "aws s3 rm s3://${aws_s3_bucket.mi_bucket_s3.bucket} --recursive"
  }

  triggers = {
    bucket_name = aws_s3_bucket.mi_bucket_s3.id
  }
}


# Configuración de ACL para el bucket
# resource "aws_s3_bucket_ownership_controls" "mi_bucket_ownership_controls" {
#   bucket = aws_s3_bucket.mi_bucket_s3.id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

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

resource "aws_iam_user" "dev_user" {
  name = "dev_s3_user"
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}

resource "aws_iam_policy" "dev_s3_policy" {
  name        = "devS3Policy"
  description = "Permite acceso Get/Put en el bucket dev"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.mi_bucket_s3.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "dev_s3_policy_attachment" {
  name       = "devS3PolicyAttachment"
  users      = [aws_iam_user.dev_user.name]
  policy_arn = aws_iam_policy.dev_s3_policy.arn
}

resource "aws_iam_access_key" "dev_access_key" {
  user = aws_iam_user.dev_user.name
}

output "access_key_id" {
  value       = aws_iam_access_key.dev_access_key.id
  sensitive   = true
  description = "Access Key para el usuario dev"
}

output "secret_access_key" {
  value       = aws_iam_access_key.dev_access_key.secret
  sensitive   = true
  description = "Secret Key para el usuario dev"
}
