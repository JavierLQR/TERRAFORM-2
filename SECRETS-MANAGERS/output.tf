output "show_password_arn_db_password" {
  description = "ARN of the Secrets Manager secret for the database password"
  value       = aws_secretsmanager_secret.db_password.arn

}
