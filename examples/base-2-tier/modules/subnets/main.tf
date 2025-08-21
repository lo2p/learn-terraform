resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = var.vpc_id
  availability_zone       = var.azs[count.index]
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = var.vpc_id
  availability_zone = var.azs[count.index]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 16)
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index}"
    Tier = "private"
  })
}
