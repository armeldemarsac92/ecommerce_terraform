resource "aws_lb" "main" {
  name        = "lb-${var.project_name}"
  client_keep_alive                                            = 3600
  desync_mitigation_mode                                       = "defensive"
  drop_invalid_header_fields                                   = false
  enable_cross_zone_load_balancing                             = true
  enable_deletion_protection                                   = false
  enable_http2                                                 = true
  enable_tls_version_and_cipher_suite_headers                  = false
  enable_waf_fail_open                                         = false
  enable_xff_client_port                                       = false
  enable_zonal_shift                                           = false
  idle_timeout                                                 = 60
  internal                                                     = false
  ip_address_type                                              = "dualstack"
  load_balancer_type                                           = "application"
  preserve_host_header                                         = false
  security_groups                                              = [
    aws_security_group.main.id
  ]
  subnets                                                      = var.public_subnet_ids
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
}

resource "aws_route53_record" "a_records" {
  for_each = toset(var.domains)

  zone_id = var.external_dns_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "aaaa_records" {
  for_each = toset(var.domains)

  zone_id = var.external_dns_zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}


resource "aws_lb_listener" "main" {
  certificate_arn                                                       = "arn:aws:acm:eu-central-1:502863813996:certificate/1cd8114a-0789-4ac7-b3f9-dc01576cf8ef"
  load_balancer_arn                                                     = aws_lb.main.arn
  port                                                                  = 443
  protocol                                                              = "HTTPS"
  routing_http_response_server_enabled                                  = true
  ssl_policy                                                            = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }

  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.frontend.arn
    type             = "forward"

    forward {
      stickiness {
        duration = 3600
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.frontend.arn
        weight = 1
      }
    }
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 2
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }

  action {
    order            = 1
    target_group_arn = aws_lb_target_group.auth.arn
    type             = "forward"

    forward {
      stickiness {
        duration = 3600
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.auth.arn
        weight = 1
      }
    }
  }

  condition {
    host_header {
      values = [
        "auth.*",
      ]
    }
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 3
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }

  action {
    order            = 1
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"

    forward {
      stickiness {
        duration = 3600
        enabled  = false
      }
      target_group {
        arn    = aws_lb_target_group.api.arn
        weight = 1
      }
    }
  }

  condition {
    host_header {
      values = [
        "api.*",
      ]
    }
  }
}



resource "aws_lb_target_group" "auth" {
  name        = "lb-tg-auth-${var.project_name}"
  vpc_id = var.vpc_id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 8080
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  tags                              = {}
  tags_all                          = {}
  target_type                       = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/auth/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_lb_target_group" "api" {
  name        = "lb-tg-api-${var.project_name}"
  vpc_id = var.vpc_id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 8080
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  tags                              = {}
  tags_all                          = {}
  target_type                       = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "lb-tg-frontend-${var.project_name}"
  vpc_id = var.vpc_id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 3000
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  tags                              = {}
  tags_all                          = {}
  target_type                       = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/sign-in"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    cookie_duration = 86400
    cookie_name     = null
    enabled         = false
    type            = "lb_cookie"
  }
}

resource "aws_security_group" "main" {
  name        = "sg_load_balancer_${var.project_name}"
  description = "Security group ffor the load balancer of ${var.project_name}."
  egress      = [
    {
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      description      = null
      from_port        = 0
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]
  ingress     = [
    {
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      description      = null
      from_port        = 443
      ipv6_cidr_blocks = [
        "::/0",
      ]
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 443
    },
  ]
  name_prefix = null
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "auth_server_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = var.auth_security_group_id

  description = "Allow traffic to the auth server from the load balancer"
}

resource "aws_security_group_rule" "api_server_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = var.api_security_group_id

  description = "Allow traffic to the api server from the load balancer"
}

resource "aws_security_group_rule" "frontend_server_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = var.frontend_security_group_id

  description = "Allow traffic to the frontend server from the load balancer"
}

