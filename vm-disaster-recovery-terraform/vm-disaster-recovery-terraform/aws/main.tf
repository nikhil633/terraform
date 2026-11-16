data "aws_caller_identity" "current" {}

# KMS key used by the primary-region backup vault.
resource "aws_kms_key" "primary_backup" {
  description             = "KMS key for AWS Backup in ${var.primary_region}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name      = "${var.name_prefix}-primary-backup-key"
    ManagedBy = "Terraform"
  }
}

resource "aws_kms_alias" "primary_backup" {
  name          = "alias/${var.name_prefix}-primary-backup"
  target_key_id = aws_kms_key.primary_backup.key_id
}

# Primary-region backup vault.
resource "aws_backup_vault" "primary" {
  name        = "${var.name_prefix}-primary-backup-vault"
  kms_key_arn = aws_kms_key.primary_backup.arn

  tags = {
    Name      = "${var.name_prefix}-primary-backup-vault"
    ManagedBy = "Terraform"
  }
}

# KMS key and vault in the disaster-recovery region.
resource "aws_kms_key" "destination_backup" {
  provider                = aws.dr
  description             = "KMS key for copied AWS Backup recovery points"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name      = "${var.name_prefix}-dr-backup-key"
    ManagedBy = "Terraform"
  }
}

resource "aws_kms_alias" "destination_backup" {
  provider      = aws.dr
  name          = "alias/${var.name_prefix}-dr-backup"
  target_key_id = aws_kms_key.destination_backup.key_id
}

resource "aws_backup_vault" "destination" {
  provider    = aws.dr
  name        = "${var.name_prefix}-dr-backup-vault"
  kms_key_arn = aws_kms_key.destination_backup.arn

  tags = {
    Name      = "${var.name_prefix}-dr-backup-vault"
    ManagedBy = "Terraform"
  }
}

# AWS Backup assumes this role when creating and restoring backups.
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
  name               = "${var.name_prefix}-aws-backup-role"
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

# Daily backup at 20:00 UTC, retained for 30 days.
# A copy of each recovery point is sent to the destination-region vault.
resource "aws_backup_plan" "ec2" {
  name = "${var.name_prefix}-daily-backup-plan"

  rule {
    rule_name         = "daily-ec2-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 20 * * ? *)"

    start_window      = 60
    completion_window = 360

    lifecycle {
      delete_after = 30
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.destination.arn

      lifecycle {
        delete_after = 30
      }
    }

    recovery_point_tags = {
      Backup   = "daily"
      ManagedBy = "Terraform"
    }
  }

  depends_on = [
    aws_backup_vault.primary,
    aws_backup_vault.destination
  ]
}

# Select exactly the existing EC2 instance supplied through terraform.tfvars.
resource "aws_backup_selection" "ec2" {
  name         = "${var.name_prefix}-ec2-selection"
  plan_id      = aws_backup_plan.ec2.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [var.ec2_instance_arn]

  depends_on = [
    aws_iam_role_policy_attachment.backup,
    aws_iam_role_policy_attachment.restore
  ]
}
