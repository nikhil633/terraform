output "aks_cluster_id" {
  value = data.azurerm_kubernetes_cluster.target.id
}

output "backup_vault_id" {
  value = azurerm_data_protection_backup_vault.aks.id
}

output "backup_storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "backup_container_name" {
  value = azurerm_storage_container.backup.name
}

output "backup_policy_id" {
  value = azurerm_data_protection_backup_policy_kubernetes_cluster.daily.id
}

output "backup_instance_id" {
  value = azurerm_data_protection_backup_instance_kubernetes_cluster.aks.id
}

output "backup_instance_protection_state" {
  value = azurerm_data_protection_backup_instance_kubernetes_cluster.aks.protection_state
}
