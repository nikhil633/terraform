output "primary_backup_vault_arn" {
  value = aws_backup_vault.primary.arn
}

output "destination_backup_vault_arn" {
  value = aws_backup_vault.destination.arn
}

output "backup_plan_id" {
  value = aws_backup_plan.ec2.id
}

output "backup_selection_id" {
  value = aws_backup_selection.ec2.id
}

output "backup_role_arn" {
  value = aws_iam_role.backup.arn
}
