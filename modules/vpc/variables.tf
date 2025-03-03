#vpc vars

variable "project_name"{
  description = "The name of the project, used to identify ressources globally."
  type        = string
  default     = "example-project"
}

variable "environment" {
  description = "The environment where this infrastructure will be deployed, used to distinguish resources."
  type        = string
}