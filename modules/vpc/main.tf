resource "aws_vpc" "main" {
  assign_generated_ipv6_cidr_block     = true
  cidr_block                           = "172.30.0.0/16"
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = false
  instance_tenancy                     = "default"

  tags                                 = {
    "Name"   = "${var.project_name}_vpc"
    "Project" = var.project_name
  }
  tags_all                             = {
    "Project" = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"   = "${var.project_name}_igw"
    "Project" = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    "Name"   = "${var.project_name}_rtb_public"
    "Project" = var.project_name
  }
}

resource "aws_subnet" "public_subnet" {
  count                                          = 3
  availability_zone                              = "eu-central-1${["a", "b", "c"][count.index]}"
  cidr_block                                     = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  map_public_ip_on_launch                        = true

  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  assign_ipv6_address_on_creation                = true

  private_dns_hostname_type_on_launch            = "ip-name"
  tags                                           = {
    "Name"    = "${var.project_name}-subnet-public-eu-central-1${["a", "b", "c"][count.index]}"
    "Project" = var.project_name
  }
  vpc_id                                         = aws_vpc.main.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name"   = "${var.project_name}_rtb_private"
    "Project" = var.project_name
  }
}

resource "aws_subnet" "private_subnet" {
  count                                          = 3
  availability_zone                              = "eu-central-1${["a", "b", "c"][count.index]}"
  cidr_block                                     = cidrsubnet(aws_vpc.main.cidr_block, 4, 3 + count.index)
  enable_dns64                                   = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  map_public_ip_on_launch                        = false

  ipv6_cidr_block                                = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 3 + count.index)
  assign_ipv6_address_on_creation                = true

  private_dns_hostname_type_on_launch            = "ip-name"
  tags                                           = {
    "Name"    = "${var.project_name}-subnet-private-eu-central-1${["a", "b", "c"][count.index]}"
    "Project" = var.project_name
  }
  vpc_id                                         = aws_vpc.main.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private.id
}