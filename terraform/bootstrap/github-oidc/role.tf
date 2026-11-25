# Allow KingdomGoods workflows on main to assume the dev Terraform role.
resource "aws_iam_role" "github_terraform" {
  name = "kingdomgoods-dev-github-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:Gabinsime75@115108532/KingdomGoods@1463632573:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}