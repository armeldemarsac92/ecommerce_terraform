resource "aws_service_discovery_http_namespace" "main" {
  description = null
  name        = "${var.project_name}_http_ns"
  tags        = {
    "Project" = var.project_name
    "AmazonECSManaged" = "true"
  }
  tags_all    = {
    "Project" = var.project_name
    "AmazonECSManaged" = "true"
  }
}

resource "aws_ecs_cluster" "main" {
  name     = "${var.project_name}_cluster"
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

#region authentication

resource "aws_ecs_service" "auth" {
  availability_zone_rebalancing      = "ENABLED"
  cluster                            = aws_ecs_cluster.main.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  name                               = "auth"
  propagate_tags                     = "NONE"
  scheduling_strategy                = "REPLICA"
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_definition                    = aws_ecs_task_definition.auth.arn
  triggers                           = {}

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  load_balancer {
    container_name   = "tdev_auth"
    container_port   = 8080
    elb_name         = null
    target_group_arn = var.target_group_arns.auth
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [
      aws_security_group.auth.id
    ]
    subnets          = var.public_subnet_ids
  }
}

resource "aws_security_group" "auth" {
  name        = "sg_auth_server_${var.project_name}"
  description = "Security group for the authentication server of ${var.project_name}."
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
  name_prefix = null
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "database_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.auth.id
  security_group_id        = var.database_security_group_id

  description = "Allow PostgreSQL accessss from the auth container"
}


resource "aws_ecs_task_definition" "auth" {
  container_definitions    = jsonencode(
    [
      {
        environment      = [
          {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Production"
          },
        ]
        essential        = true
        image            = "502863813996.dkr.ecr.eu-central-1.amazonaws.com/t-dev-702/prod/auth:latest"
        logConfiguration = {
          logDriver     = "awslogs"
          options       = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/tdev_auth"
            awslogs-region        = "eu-central-1"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints      = []
        name             = "tdev_auth"
        portMappings     = [
          {
            appProtocol   = "http"
            containerPort = 8080
            hostPort      = 8080
            name          = "auth"
            protocol      = "tcp"
          },
        ]
        systemControls   = []
        volumesFrom      = []
      },
    ]
  )
  cpu                      = "256"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::502863813996:role/ecsTaskExecutionRole"
  family                   = "tdev_auth"
  ipc_mode                 = null
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = [
    "FARGATE",
  ]
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_role_arn            = "arn:aws:iam::502863813996:role/ECSSeeqrRole"
  track_latest             = false

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

#endregion authentication

#region api

resource "aws_ecs_service" "api" {
  availability_zone_rebalancing      = "ENABLED"
  cluster                            = aws_ecs_cluster.main.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  name                               = "api"
  platform_version                   = "LATEST"
  propagate_tags                     = "NONE"
  scheduling_strategy                = "REPLICA"
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_definition                    = aws_ecs_task_definition.api.arn
  triggers                           = {}

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  load_balancer {
    container_name   = "tdev_api"
    container_port   = 8080
    elb_name         = null
    target_group_arn = var.target_group_arns.api
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [
      aws_security_group.api.id
    ]
    subnets          = var.public_subnet_ids
  }
}

resource "aws_security_group" "api" {
  name        = "sg_api_${var.project_name}"
  description = "Security group for the api server of ${var.project_name}."
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
  name_prefix = null
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  vpc_id      = var.vpc_id
}

resource "aws_ecs_task_definition" "api" {
  container_definitions    = jsonencode(
    [
      {
        environment      = [
          {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Production"
          },
        ]
        essential        = true
        image            = "502863813996.dkr.ecr.eu-central-1.amazonaws.com/t-dev-702/prod/api:latest"
        logConfiguration = {
          logDriver     = "awslogs"
          options       = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/tdev_api"
            awslogs-region        = "eu-central-1"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints      = []
        name             = "tdev_api"
        portMappings     = [
          {
            appProtocol   = "http"
            containerPort = 8080
            hostPort      = 8080
            name          = "api"
            protocol      = "tcp"
          },
        ]
        systemControls   = []
        volumesFrom      = []
      },
    ]
  )
  cpu                      = "256"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::502863813996:role/ecsTaskExecutionRole"
  family                   = "tdev_api"
  ipc_mode                 = null
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = [
    "FARGATE",
  ]
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_role_arn            = "arn:aws:iam::502863813996:role/ECSSeeqrRole"
  track_latest             = false

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

#endregion api

#region frontend

resource "aws_ecs_service" "frontend" {
  availability_zone_rebalancing      = "ENABLED"
  cluster                            = aws_ecs_cluster.main.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = true
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  name                               = "frontend"
  platform_version                   = "LATEST"
  propagate_tags                     = "NONE"
  scheduling_strategy                = "REPLICA"
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_definition                    = aws_ecs_task_definition.frontend.arn
  triggers                           = {}

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  load_balancer {
    container_name   = "tdev_frontend"
    container_port   = 3000
    elb_name         = null
    target_group_arn = var.target_group_arns.frontend
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [
      aws_security_group.frontend.id
    ]
    subnets          = var.public_subnet_ids
  }
}

resource "aws_security_group" "frontend" {
  name        = "sg_frontend_${var.project_name}"
  description = "Security group for the frontend server of ${var.project_name}."
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
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  vpc_id      = var.vpc_id
}



resource "aws_ecs_task_definition" "frontend" {
  container_definitions    = jsonencode(
    [
      {
        environment      = [
          {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = "Production"
          },
        ]
        essential        = true
        image            = "502863813996.dkr.ecr.eu-central-1.amazonaws.com/t-dev-702/prod/frontend:latest"
        logConfiguration = {
          logDriver     = "awslogs"
          options       = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/tdev_frontend"
            awslogs-region        = "eu-central-1"
            awslogs-stream-prefix = "ecs"
            max-buffer-size       = "25m"
            mode                  = "non-blocking"
          }
          secretOptions = []
        }
        mountPoints      = []
        name             = "tdev_api"
        portMappings     = [
          {
            appProtocol   = "http"
            containerPort = 3000
            hostPort      = 3000
            name          = "frontend"
            protocol      = "tcp"
          },
        ]
        systemControls   = []
        volumesFrom      = []
      },
    ]
  )
  cpu                      = "256"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::502863813996:role/ecsTaskExecutionRole"
  family                   = "tdev_frontend"
  ipc_mode                 = null
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = [
    "FARGATE",
  ]
  tags                                 = {
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
  task_role_arn            = "arn:aws:iam::502863813996:role/ECSSeeqrRole"
  track_latest             = false

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

#endregion frontend

