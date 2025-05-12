variable "bucket_name" {
  type        = string
  description = "Name of the bucket"
  default     = "my-bucket-unique-123"
}

variable "name_user" {
  type        = string
  description = "Name of the user"
  default     = "devOnlyS3"
}
