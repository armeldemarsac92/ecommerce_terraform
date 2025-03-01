#vpc vars

variable "project_name"{
  description = "The name of the project, used to identify ressources globally."
  type        = string
  default     = "example-project"
}