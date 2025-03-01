#ecs vars

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

variable "load_balancer_id" {
  description = "The ARN of the load balancer"
  type        = string
}

variable "load_balancer_arn" {
  description = "The ARN of the load balancer"
  type        = string
}

variable "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  type        = string
}

variable "load_balancer_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  type        = string
}

variable "target_group_arns" {
  description = "Map of target group ARNs"
  type        = map(string)
}

variable "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  type        = string
}

variable "domain_records" {
  description = "Map of domain names to their Route53 record IDs"
  type        = map(object({
    a_record    = string
    aaaa_record = string
  }))
}

variable "project_name"{
  description = "The name of the project, used to identify ressources globally."
  type        = string
  default     = "example-project.fr"
}

variable "database_security_group_id" {
  description = "The ID of the database security group"
  type        = string
}