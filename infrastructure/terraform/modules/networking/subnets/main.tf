resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name                                        = "public-subnet-${var.environment}-${count.index + 1}"
      Environment                                 = var.environment
      Type                                        = "public"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    },
    # Add internal-elb tag for public subnets when used for EKS nodes (testing env)
    var.use_public_subnets_for_eks ? {
      "kubernetes.io/role/internal-elb" = "1"
    } : {}
  )
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                        = "private-subnet-${var.environment}-${count.index + 1}"
    Environment                                 = var.environment
    Type                                        = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Conditional NAT Gateway creation
locals {
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = {
    Name        = "nat-eip-${var.environment}-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "nat-gw-${var.environment}-${count.index + 1}"
    Environment = var.environment
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name        = "public-rt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id

  # Conditional route for NAT Gateway
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = {
    Name        = "private-rt-${var.environment}-${count.index + 1}"
    Environment = var.environment
    Type        = var.enable_nat_gateway ? "with-nat" : "isolated"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}