# github-oidc.tf

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's OIDC certificate thumbprint
  thumbprint_list = [
    "ffffffffffffffffffffffffffffffffffffffff"
  ]

  tags = {
    Name        = "github-actions-oidc"
    Environment = "production"
  }
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:nikhil633/terraform:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-terraform-role"
  }
}


resource "aws_iam_role_policy_attachment" "github_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# resource "aws_iam_policy" "terraform" {
#   name = "github-actions-terraform-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"

#     Statement = [
#       {
#         Effect = "Allow"

#         Action = [
#           "ec2:*",
#           "iam:GetRole",
#           "iam:CreateRole",
#           "iam:DeleteRole",
#           "iam:AttachRolePolicy",
#           "iam:DetachRolePolicy",
#           "iam:PassRole"
#         ]

#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "terraform" {
#   role       = aws_iam_role.github_actions.name
#   policy_arn = aws_iam_policy.terraform.arn
# }


output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

