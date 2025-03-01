#datbase vars

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

variable "internal_dns_zone_name"{
  description = "The name of the internal DNS zone"
  default = "internal.example-project.fr"
  type        = string
}

variable "database_host_name" {
  description = "The internal host name of the database instance"
  default = "db.internal.example-project.fr"
  type        = string
}

variable "project_name"{
  description = "The name of the project, used to identify ressources globally."
  type        = string
  default     = "example-project"
}

variable "database_name"{
  description = "The name of the database."
  type        = string
  default     = "example-database"
}

variable "db_engine" {
  description = "Database engine type"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Version of the database engine"
  type        = string
  default     = "16.3"
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t4g.micro"
}