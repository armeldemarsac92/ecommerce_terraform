output "auth_security_group_id" {
  description = "The ID of the auth security group"
  value       = aws_security_group.auth.id
}

output "api_security_group_id" {
  description = "The ID of the api security group"
  value       = aws_security_group.api.id
}

output "frontend_security_group_id" {
  description = "The ID of the frontend security group"
  value       = aws_security_group.frontend.id
}