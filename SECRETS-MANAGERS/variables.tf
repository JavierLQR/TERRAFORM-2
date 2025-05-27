variable "env" {
  description = "Environment name (e.g., dev, prod)"
  default     = "dev-test"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

