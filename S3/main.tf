
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
# Recurso que configura el control de propiedad de objetos en un bucket S3
resource "aws_s3_bucket_ownership_controls" "mi_bucket_ownership_controls" {
  # Especificamos el ID del bucket al que se aplicará este control
  bucket = aws_s3_bucket.mi_bucket_s3.id
  # Definimos la regla de propiedad de los objetos
  rule {
    # Esta opción "BucketOwnerEnforced" hace que:
    # - El propietario del bucket será el propietario de todos los objetos cargados,
    #   incluso si fueron subidos por otro usuario o cuenta.
    # - Las ACLs (listas de control de acceso) quedan completamente desactivadas.
    #   Es decir, no se puede usar "public-read" ni otras ACLs.
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
# resource "aws_s3_bucket_acl" "mi_bucket_acl" {

#   depends_on = [
#     aws_s3_bucket_public_access_block.mi_bucket_public_access_block
#   ]

#   bucket = aws_s3_bucket.mi_bucket_s3.id
#   acl    = "public-read"

# }


# Crear el usuario iam para el bucket
resource "aws_iam_user" "dev_user" {
  name = var.name_user
  tags = {
    Name        = "Mi bucket"
    Environment = "Dev"
  }
}

# Configuración de ACCESS KEY y secret KEY para el usuario
resource "aws_iam_access_key" "dev_access_key" {
  user = aws_iam_user.dev_user.name
}

