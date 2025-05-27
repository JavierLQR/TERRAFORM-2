output "secret_password_arn" {
  description = "ARN of the Secrets Manager secret for the database password"
  value       = aws_secretsmanager_secret.db_password.arn

}
