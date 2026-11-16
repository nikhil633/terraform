output "backup_resource_group_name" {
  value = azurerm_resource_group.backup.name
}

output "recovery_services_vault_id" {
  value = azurerm_recovery_services_vault.vm.id
}

output "backup_policy_id" {
  value = azurerm_backup_policy_vm.daily.id
}

output "protected_vm_backup_id" {
  value = azurerm_backup_protected_vm.existing_vm.id
}
