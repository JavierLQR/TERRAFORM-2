
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

output "name_bucket" {
  value       = aws_s3_bucket.mi_bucket_s3.id
  description = "Name of the bucket"
  sensitive   = false
}


output "name_user" {
  value       = aws_iam_user.dev_user.name
  description = "Name of the user"
  sensitive   = false

}
