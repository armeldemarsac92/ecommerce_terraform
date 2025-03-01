#load balancer vars

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "domains" {
  description = "List of domain names to use"
  type        = list(string)
  default     = [
    "example-project.fr",
    "api.example-project.fr",
    "auth.example-project.fr"
  ]  
}

variable "external_dns_zone_id"{
  description = "The id of the external DNS zone"
  type        = string
}

variable "auth_security_group_id" {
  description = "The ID of the security group for the auth service"
  type        = string
}

variable "api_security_group_id" {
  description = "The ID of the security group for the api service"
  type        = string
}

variable "frontend_security_group_id" {
  description = "The ID of the security group for the frontend service"
  type        = string
}

variable "project_name"{
  description = "The name of the project, used to identify ressources globally."
  type        = string
  default     = "example-project.fr"
}