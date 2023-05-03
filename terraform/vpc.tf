resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(tomap({ "Name" = "${local.environment}-IGW" }), local.common_tags)
}

resource "aws_eip" "ngw_eip" {
  count = length(data.aws_availability_zones.available.names)
  vpc   = true
}

resource "aws_nat_gateway" "ngw" {
  count         = length(data.aws_availability_zones.available.names)
  allocation_id = element(aws_eip.ngw_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = merge(tomap({ "Name" = "${local.environment}-NGW-${count.index}", "az" = element(aws_subnet.public_subnet.*.availability_zone, count.index) }), local.common_tags)

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(tomap({ "Name" = "${local.environment}-public-subnet-${count.index}" }), local.common_tags)
}

resource "aws_subnet" "private_subnet" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, sum([length(data.aws_availability_zones.available.names), count.index]))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(tomap({ "Name" = "${local.environment}-private-subnet-${count.index}" }), local.common_tags)
}


resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  lifecycle {
    ignore_changes = [route]
  }

  tags = merge(tomap({ "Name" = "${local.environment}-public" }), local.common_tags)
}

resource "aws_route_table" "private_route_table" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
  }
  lifecycle {
    ignore_changes = [route]
  }

  tags = merge(tomap({ "Name" = "${local.environment}-private-${count.index}" }), local.common_tags)
}


resource "aws_route_table_association" "public" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_default_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}
