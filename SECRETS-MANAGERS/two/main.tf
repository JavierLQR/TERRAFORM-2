provider "aws" {
  region = var.region

}


# Create a secret for RabbitMQ URL
resource "aws_secretsmanager_secret" "RABBIT_URL" {
  name                    = "rabbitmq-url-${var.env}"
  description             = "RabbitMQ URL secret for ${var.env} environment"
  recovery_window_in_days = 7

  tags = {
    Environment = var.env
    Owner       = var.owner
  }

}
# Crear la versión del secret
resource "aws_secretsmanager_secret_version" "RABBIT_URL" {
  secret_id = aws_secretsmanager_secret.RABBIT_URL.id
  secret_string = jsonencode({
    url = "amqp://user:password@rabbitmq.${var.env}.example.com:5672/"
  })

}

# Outputs for the RabbitMQ URL secret
output "rabbitmq_url_arn" {
  description = "ARN of the RabbitMQ URL secret"
  value       = aws_secretsmanager_secret.RABBIT_URL.arn

}


# Outputs for the RabbitMQ URL secret version
output "rabbitmq_url" {
  description = "RabbitMQ URL secret value"
  value       = aws_secretsmanager_secret_version.RABBIT_URL.secret_string
  sensitive   = true
}


# Outputs for the RabbitMQ URL secret version ID
output "rabbitmq_url_version_id" {
  description = "Version ID of the RabbitMQ URL secret"
  value       = aws_secretsmanager_secret_version.RABBIT_URL.version_id

}
