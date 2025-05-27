variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
  type        = string
  nullable    = false
  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region)
    error_message = "Region must be either 'us-east-1' or 'us-west-2'."
  }

}


variable "env" {
  default     = "dev"
  description = "Environment name (e.g., dev, prod)"
  sensitive   = false
  nullable    = false
  type        = string
}

variable "owner" {
  description = "Owner of the secrets"
  default     = "team-a"
  type        = string

}
