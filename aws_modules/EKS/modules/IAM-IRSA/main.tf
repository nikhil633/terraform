resource "aws_iam_role" "s3_irsa_role" {

  name = "${var.cluster_name}-s3-irsa-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = var.oidc_provider_arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {

          StringEquals = {

            "${replace(
              var.oidc_issuer_url,
              "https://",
              ""
            )}:sub" = "system:serviceaccount:default:s3-access-sa"

            "${replace(
              var.oidc_issuer_url,
              "https://",
              ""
            )}:aud" = "sts.amazonaws.com"

          }
        }
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_policy" "s3_access_policy" {

  name = "${var.cluster_name}-s3-access-policy"

  description = "Allow EKS service account to access specific S3 bucket"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::${var.bucket_name}"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }

    ]
  })
}



resource "aws_iam_role_policy_attachment" "s3_irsa_attach" {

  role = aws_iam_role.s3_irsa_role.name

  policy_arn = aws_iam_policy.s3_access_policy.arn
}






resource "aws_iam_role" "ebs_csi_role" {

  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = var.oidc_provider_arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {

          StringEquals = {

            "${replace(
              var.oidc_issuer_url,
              "https://",
              ""
            )}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"

            "${replace(
              var.oidc_issuer_url,
              "https://",
              ""
            )}:aud" = "sts.amazonaws.com"

          }
        }
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {

  role = aws_iam_role.ebs_csi_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}








