variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
  type        = string
  nullable    = false
  sensitive   = false
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


variable "vpc_name" {
  default     = "my-vpc"
  description = "Name of the VPC"
  sensitive   = false
  nullable    = false
  type        = string

}


variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "availability_zone" {
  default = "us-east-1a"
}
