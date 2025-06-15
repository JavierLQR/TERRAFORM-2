variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
  type        = string

}

variable "node_env" {
  default     = "dev"
  description = "Environment name (e.g., dev, prod)"
  sensitive   = false
  nullable    = false
  type        = string

}

variable "team" {
  default     = "team-a"
  description = "Team name"
  sensitive   = false
  nullable    = false
  type        = string
}

