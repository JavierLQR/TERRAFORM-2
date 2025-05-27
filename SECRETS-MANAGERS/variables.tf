variable "env_test" {
  description = "Environment name (e.g., dev, prod)"
  default     = "dev-test"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["dev-test", "prod-test"], var.env_test)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

