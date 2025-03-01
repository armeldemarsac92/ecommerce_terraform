resource "aws_instance" "bastion" {
  ami                         = "ami-0eddb4a4e7d846d6f"
  instance_type               = "t2.nano"
  key_name                    = "tdev700"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true
  iam_instance_profile        = "ec2Tdev702Role"

  ipv6_address_count         = 1

  tags = {
    Name = "bastion ${var.project_name}"
    Project = var.project_name
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    throughput  = 125
    iops        = 3000
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  credit_specification {
    cpu_credits = "standard"
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = var.route53_zone_id
  name    = var.bastion_host_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.bastion.public_ip]
}

resource "aws_security_group" "main" {
  name        = "bastion_sg_${var.project_name}"
  description = "Security group of   the bastion host of ${var.project_name}."
  vpc_id      = var.vpc_id

  egress {
    from_port        = 5432 
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow SSH inbound from anywhere"
  }

  tags = {
    "Project" = var.project_name
  }
}

resource "aws_security_group_rule" "database_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id        = var.database_security_group_id

  description = "Allow traffic to the database from the bastion host."
}

