variable "env" {
  description = "Environment name (e.g., dev, prod)"
  default     = "dev"
  type        = string
  nullable    = false
  sensitive   = false
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

