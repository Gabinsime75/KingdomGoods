# Give the private application subnets direct access to regional S3.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.dev.id
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.application.id]

  tags = {
    Name = "kingdomgoods-dev-s3-endpoint"
  }
}