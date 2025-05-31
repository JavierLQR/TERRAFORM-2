variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}


variable "cluster_name" {
  default     = "cluster-test-${var.environment}"
  description = "Name of the cluster"
  nullable    = false

}
