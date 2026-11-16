# Keep the backup vault in the same region as the protected VM.
# This resource group is dedicated to backup resources.
resource "azurerm_resource_group" "backup" {
  name     = var.backup_resource_group_name
  location = var.vm_location

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "VM backup and disaster recovery"
  }
}

resource "azurerm_recovery_services_vault" "vm" {
  name                = var.recovery_vault_name
  location            = azurerm_resource_group.backup.location
  resource_group_name = azurerm_resource_group.backup.name
  sku                 = "Standard"

  # Geo-redundant storage supports Cross Region Restore.
  storage_mode_type           = "GeoRedundant"
  cross_region_restore_enabled = true
  soft_delete_enabled          = true

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "VM backup and disaster recovery"
  }
}

# Daily backup policy with 30-day daily retention.
resource "azurerm_backup_policy_vm" "daily" {
  name                = var.backup_policy_name
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.vm.name

  backup {
    frequency = "Daily"
    time      = var.backup_time_utc
  }

  retention_daily {
    count = 30
  }
}

# Protect the existing VM by its full Azure resource ID.
resource "azurerm_backup_protected_vm" "existing_vm" {
  resource_group_name = azurerm_resource_group.backup.name
  recovery_vault_name = azurerm_recovery_services_vault.vm.name

  source_vm_id     = var.vm_resource_id
  backup_policy_id = azurerm_backup_policy_vm.daily.id
}
