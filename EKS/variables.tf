variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "region_name" {
  description = "Region"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.region_name)
    error_message = "Region must be either 'us-east-1' or 'us-west-2'."
  }

}
