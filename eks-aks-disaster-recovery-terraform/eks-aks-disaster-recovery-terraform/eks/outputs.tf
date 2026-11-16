output "primary_backup_vault_arn" {
  value = aws_backup_vault.primary.arn
}

output "dr_backup_vault_arn" {
  value = aws_backup_vault.dr.arn
}

output "backup_plan_id" {
  value = aws_backup_plan.eks.id
}

output "backup_selection_id" {
  value = aws_backup_selection.eks.id
}

output "backup_service_role_arn" {
  value = aws_iam_role.backup.arn
}
