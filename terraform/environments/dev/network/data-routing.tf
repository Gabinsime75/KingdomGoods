# Keep the private data subnets on VPC-local routing.
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.dev.id

  tags = {
    Name = "kingdomgoods-dev-data"
  }
}

resource "aws_route_table_association" "data" {
  for_each = aws_subnet.data

  subnet_id      = each.value.id
  route_table_id = aws_route_table.data.id
}