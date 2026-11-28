# Store KingdomGoods dev VPC Flow Logs in CloudWatch Logs.
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/kingdomgoods/dev/vpc-flow-logs"
  retention_in_days = 14
}

# Trust VPC Flow Logs from the dev account in us-west-2.
resource "aws_iam_role" "vpc_flow_logs" {
  name = "kingdomgoods-dev-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = aws_vpc.dev.owner_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ec2:us-west-2:${aws_vpc.dev.owner_id}:vpc-flow-log/*"
          }
        }
      }
    ]
  })
}

# Allow the VPC Flow Logs service to publish to its dedicated log group.
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "publish-vpc-flow-logs"
  role = aws_iam_role.vpc_flow_logs.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListLogGroups"
        Effect   = "Allow"
        Action   = "logs:DescribeLogGroups"
        Resource = "*"
      },
      {
        Sid      = "ManageFlowLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:DescribeLogStreams"]
        Resource = aws_cloudwatch_log_group.vpc_flow_logs.arn
      },
      {
        Sid      = "WriteFlowLogStreams"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:log-stream:*"
      }
    ]
  })
}

# Publish dev VPC flow logs to the dedicated CloudWatch log group.
resource "aws_flow_log" "dev" {
  vpc_id               = aws_vpc.dev.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  tags = {
    Name = "kingdomgoods-dev-vpc-flow-logs"
  }

  depends_on = [aws_iam_role_policy.vpc_flow_logs]
}