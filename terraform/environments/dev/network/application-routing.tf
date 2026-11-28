# Provide outbound IPv4 access for the private application subnets.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "kingdomgoods-dev-nat-eip"
  }
}

resource "aws_nat_gateway" "dev" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.public["usw2-az2"].id
  connectivity_type = "public"

  tags = {
    Name = "kingdomgoods-dev-nat"
  }

  depends_on = [aws_internet_gateway.dev]
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "kingdomgoods-dev-application"
  }
}

resource "aws_route" "application_egress" {
  route_table_id         = aws_route_table.application.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.dev.id
}

resource "aws_route_table_association" "application" {
  for_each = aws_subnet.application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.application.id
}