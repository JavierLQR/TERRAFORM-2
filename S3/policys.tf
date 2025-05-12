
# Configuración de ACL para el bucket( bucket )
resource "aws_s3_bucket_policy" "dev_bucket_policy" {
  bucket = aws_s3_bucket.mi_bucket_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadAccess",
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
        ]
        Resource = "${aws_s3_bucket.mi_bucket_s3.arn}/*"
      }
    ]
  })
}



#-- USER --#
# Configuración de iam para el bucket( usuario) )
resource "aws_iam_policy" "dev_s3_policy" {
  name        = "devS3Policy"
  description = "Permite acceso Get/Put en el bucket dev"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DevS3Policy"
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

# Configuración para asignar las politicas para el usuario
resource "aws_iam_policy_attachment" "dev_s3_policy_attachment" {
  name       = "devS3PolicyAttachment"
  users      = [aws_iam_user.dev_user.name]
  policy_arn = aws_iam_policy.dev_s3_policy.arn
}
# -- USER --#
