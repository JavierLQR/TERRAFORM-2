variable "type_instance" {
  type        = string
  default     = "t2.micro"
  description = "Instance type"
}


variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"

}


variable "server_name" {
  description = "Server name"
  type        = string
  default     = "nginx-server"
}
