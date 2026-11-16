data "aws_caller_identity" "current" {}

# KMS key and vault in the primary region.
resource "aws_kms_key" "primary" {
  description             = "KMS key for EKS AWS Backup recovery points"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name      = "${var.name_prefix}-backup-primary-key"
    ManagedBy = "Terraform"
  }
}

resource "aws_backup_vault" "primary" {
  name        = "${var.name_prefix}-primary-backup-vault"
  kms_key_arn = aws_kms_key.primary.arn

  tags = {
    Name      = "${var.name_prefix}-primary-backup-vault"
    ManagedBy = "Terraform"
  }
}

# Separate KMS key and vault in the destination region.
resource "aws_kms_key" "dr" {
  provider                = aws.dr
  description             = "KMS key for EKS DR recovery points"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name      = "${var.name_prefix}-backup-dr-key"
    ManagedBy = "Terraform"
  }
}

resource "aws_backup_vault" "dr" {
  provider    = aws.dr
  name        = "${var.name_prefix}-dr-backup-vault"
  kms_key_arn = aws_kms_key.dr.arn

  tags = {
    Name      = "${var.name_prefix}-dr-backup-vault"
    ManagedBy = "Terraform"
  }
}

# AWS Backup assumes this role to back up and restore the EKS cluster and
# supported persistent resources. The AWS-managed policy includes EKS/EBS/EFS
# permissions documented for EKS backups.
data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.name_prefix}-backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "eks" {
  name = "${var.name_prefix}-daily-backup-plan"

  rule {
    rule_name         = "daily-eks-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 20 * * ? *)" # Daily at 20:00 UTC

    start_window      = 60
    completion_window = 360

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = 30
      }
    }

    recovery_point_tags = {
      Backup    = "daily"
      Workload  = "eks"
      ManagedBy = "Terraform"
    }
  }

  depends_on = [
    aws_backup_vault.primary,
    aws_backup_vault.dr
  ]
}

# Select the existing EKS cluster. AWS Backup creates a composite recovery point
# with child recovery points for supported persistent resources attached via PVCs.
resource "aws_backup_selection" "eks" {
  name         = "${var.name_prefix}-cluster-selection"
  plan_id      = aws_backup_plan.eks.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [var.eks_cluster_arn]

  depends_on = [
    aws_iam_role_policy_attachment.backup,
    aws_iam_role_policy_attachment.restore
  ]
}
