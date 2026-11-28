# Route public subnet traffic through the dev VPC internet gateway.
resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "kingdomgoods-dev-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "kingdomgoods-dev-public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}