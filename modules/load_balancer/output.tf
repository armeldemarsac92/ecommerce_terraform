output "load_balancer_id" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.id
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "The canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arns" {
  description = "Map of target group ARNs"
  value = {
    frontend = aws_lb_target_group.frontend.arn
    api      = aws_lb_target_group.api.arn
    auth     = aws_lb_target_group.auth.arn
  }
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = aws_lb_listener.main.arn
}

output "domain_records" {
  description = "Map of domain names to their Route53 record IDs"
  value = {
    for domain in var.domains : domain => {
      a_record    = aws_route53_record.a_records[domain].id
      aaaa_record = aws_route53_record.aaaa_records[domain].id
    }
  }
}