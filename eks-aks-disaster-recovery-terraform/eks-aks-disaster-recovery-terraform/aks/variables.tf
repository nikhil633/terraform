variable "subscription_id" {
  description = "Subscription containing the existing AKS cluster."
  type        = string
}

variable "aks_name" {
  description = "Name of the existing AKS cluster."
  type        = string
}

variable "aks_resource_group_name" {
  description = "Resource group containing the existing AKS cluster."
  type        = string
}

variable "backup_resource_group_name" {
  description = "Dedicated resource group for AKS backup resources."
  type        = string
  default     = "rg-aks-backup"
}

variable "snapshot_resource_group_name" {
  description = "Separate resource group for persistent volume snapshots."
  type        = string
  default     = "rg-aks-backup-snapshots"
}

variable "backup_vault_name" {
  description = "Globally unique within the subscription/resource naming constraints."
  type        = string
  default     = "aks-backup-vault-change-me"
}

variable "storage_account_name" {
  description = "Globally unique 3-24 character lowercase alphanumeric storage account name."
  type        = string
}

variable "storage_container_name" {
  description = "Private Blob container used by the AKS Backup extension."
  type        = string
  default     = "aks-backup"
}

variable "backup_policy_name" {
  description = "Name of the AKS backup policy."
  type        = string
  default     = "aks-daily-backup-policy"
}

variable "backup_start_datetime_utc" {
  description = "UTC start datetime for daily recurrence, e.g. 2026-11-14T20:00:00Z. Set to a future UTC time."
  type        = string
  default     = "2026-11-14T20:00:00Z"
}

variable "backup_retention_days" {
  description = "Operational-tier retention duration."
  type        = number
  default     = 30
}

variable "included_namespaces" {
  description = "Namespaces to include. Empty list means all namespaces, subject to exclusions."
  type        = list(string)
  default     = []
}

variable "excluded_namespaces" {
  description = "Namespaces to exclude from backup."
  type        = list(string)
  default     = ["kube-system", "kube-public", "kube-node-lease"]
}
