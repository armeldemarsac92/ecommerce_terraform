resource "aws_db_subnet_group" "database" {
  name        = "tdev700-database-subnet-group"
  description = "Database subnet group for tdev700 RDS instances"

  subnet_ids = var.private_subnet_ids

  tags = {
    Name   = "tdev700-database-subnet-group"
    projet = var.project_name
  }
}

data "aws_db_snapshot" "final_snapshot" {
  most_recent         = true
  snapshot_type       = "manual"
  include_shared      = false
  include_public      = false

  db_snapshot_identifier = "${var.project_name}-final-snapshot"
}

resource "aws_db_instance" "postgresql" {
  identifier                          = var.database_name
  snapshot_identifier    = data.aws_db_snapshot.final_snapshot.id
  allocated_storage                   = 20
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_subnet_group_name                = aws_db_subnet_group.database.name
  vpc_security_group_ids              = [aws_security_group.main.id]

  storage_type                        = "gp3"
  storage_encrypted                   = true
  max_allocated_storage               = 1000
  iops                                = 3000
  storage_throughput                  = 125

  performance_insights_enabled        = true
  performance_insights_retention_period = 7

  backup_retention_period             = 1
  backup_window                       = "21:38-22:08"
  maintenance_window                  = "mon:02:18-mon:02:48"

  skip_final_snapshot   = false
  final_snapshot_identifier = "${var.database_name}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  publicly_accessible                 = false

}

resource "aws_route53_zone" "private" {
  name = var.internal_dns_zone_name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.private.id
  name    = var.database_host_name
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.postgresql.address]
}

resource "aws_security_group" "main" {
  name        = "sg_database_${var.project_name}"
  description = "Security group  for the database of ${var.project_name}."
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