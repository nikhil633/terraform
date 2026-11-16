data "azurerm_client_config" "current" {}

# Read the existing AKS cluster; this Terraform root does not recreate it.
data "azurerm_kubernetes_cluster" "target" {
  name                = var.aks_name
  resource_group_name = var.aks_resource_group_name
}

locals {
  aks_location = data.azurerm_kubernetes_cluster.target.location
}

resource "azurerm_resource_group" "backup" {
  name     = var.backup_resource_group_name
  location = local.aks_location

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "AKS backup"
  }
}

resource "azurerm_resource_group" "snapshots" {
  name     = var.snapshot_resource_group_name
  location = local.aks_location

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "AKS persistent volume snapshots"
  }
}

# Operational-tier AKS backup uses this storage account/container for Kubernetes
# resource data written by the Backup extension.
resource "azurerm_storage_account" "backup" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.backup.name
  location                        = azurerm_resource_group.backup.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "AKS backup extension storage"
  }
}

resource "azurerm_storage_container" "backup" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

# AKS Backup uses a Data Protection Backup Vault. This example configures
# OperationalStore only. See README for the current Vault-tier Terraform limitation.
resource "azurerm_data_protection_backup_vault" "aks" {
  name                = var.backup_vault_name
  resource_group_name = azurerm_resource_group.backup.name
  location            = local.aks_location
  datastore_type      = "OperationalStore"
  redundancy          = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "AKS operational backup"
  }
}

# Allow the Backup Vault to access the AKS cluster through Trusted Access.
resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "backup" {
  name                  = "aks-backup-trusted-access"
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.target.id
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = azurerm_data_protection_backup_vault.aks.id
}

# Install the Azure Backup extension in the existing AKS cluster.
resource "azurerm_kubernetes_cluster_extension" "backup" {
  name           = "azure-aks-backup"
  cluster_id     = data.azurerm_kubernetes_cluster.target.id
  extension_type = "microsoft.dataprotection.kubernetes"

  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                         = azurerm_storage_container.backup.name
    "configuration.backupStorageLocation.config.storageAccount"          = azurerm_storage_account.backup.name
    "configuration.backupStorageLocation.config.resourceGroup"           = azurerm_resource_group.backup.name
    "configuration.backupStorageLocation.config.subscriptionId"          = data.azurerm_client_config.current.subscription_id
    "configuration.backupStorageLocation.config.storageAccountURI"       = azurerm_storage_account.backup.primary_blob_endpoint
    "configuration.backupStorageLocation.config.useAAD"                  = "true"
    "credentials.tenantId"                                                = data.azurerm_client_config.current.tenant_id
  }

  depends_on = [
    azurerm_kubernetes_cluster_trusted_access_role_binding.backup,
    azurerm_storage_container.backup
  ]
}

# Extension managed identity can write the backup payload to the Blob container.
resource "azurerm_role_assignment" "extension_blob_data_contributor" {
  scope                = azurerm_storage_account.backup.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.backup.aks_assigned_identity[0].principal_id
}

# Backup Vault identity can read the cluster and snapshot resource group.
resource "azurerm_role_assignment" "vault_reader_on_cluster" {
  scope                = data.azurerm_kubernetes_cluster.target.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_reader_on_snapshot_rg" {
  scope                = azurerm_resource_group.snapshots.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_blob_data_contributor" {
  scope                = azurerm_storage_account.backup.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_protection_backup_vault.aks.identity[0].principal_id
}

# AKS cluster's system-assigned identity writes persistent volume snapshots here.
resource "azurerm_role_assignment" "aks_contributor_on_snapshot_rg" {
  scope                = azurerm_resource_group.snapshots.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_kubernetes_cluster.target.identity[0].principal_id
}

# Daily operational-tier backup with configurable retention.
resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "daily" {
  name                = var.backup_policy_name
  resource_group_name = azurerm_resource_group.backup.name
  vault_name          = azurerm_data_protection_backup_vault.aks.name

  backup_repeating_time_intervals = [
    "R/${var.backup_start_datetime_utc}/P1D"
  ]

  time_zone = "UTC"

  default_retention_rule {
    life_cycle {
      duration        = "P${var.backup_retention_days}D"
      data_store_type = "OperationalStore"
    }
  }

  depends_on = [
    azurerm_data_protection_backup_vault.aks
  ]
}

# Protect all namespaces by default, except the excluded system namespaces.
# Enable volume snapshots so supported disk-backed PVC data is protected.
resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "aks" {
  name                         = "${var.aks_name}-backup-instance"
  location                     = local.aks_location
  vault_id                     = azurerm_data_protection_backup_vault.aks.id
  kubernetes_cluster_id        = data.azurerm_kubernetes_cluster.target.id
  snapshot_resource_group_name = azurerm_resource_group.snapshots.name
  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.daily.id

  backup_datasource_parameters {
    excluded_namespaces              = var.excluded_namespaces
    excluded_resource_types          = []
    cluster_scoped_resources_enabled = true
    included_namespaces              = var.included_namespaces
    included_resource_types          = []
    label_selectors                  = []
    volume_snapshot_enabled          = true
  }

  depends_on = [
    azurerm_role_assignment.extension_blob_data_contributor,
    azurerm_role_assignment.vault_reader_on_cluster,
    azurerm_role_assignment.vault_reader_on_snapshot_rg,
    azurerm_role_assignment.vault_blob_data_contributor,
    azurerm_role_assignment.aks_contributor_on_snapshot_rg
  ]
}
