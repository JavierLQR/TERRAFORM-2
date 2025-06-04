variable "aws_region" {
  default     = "us-east-1"
  description = "AWS region for the EKS cluster"
}

variable "type_instance" {
  type        = string
  default     = "t3.medium"
  description = "Instance type"

}
