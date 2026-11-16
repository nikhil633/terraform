variable "subscription_id" {
  description = "Azure subscription ID containing the existing VM."
  type        = string
}

variable "vm_resource_id" {
  description = "Full resource ID of the existing Azure VM to protect."
  type        = string
}

variable "vm_location" {
  description = "Azure region where the existing VM runs; the Recovery Services Vault must be in this region."
  type        = string
  default     = "Central India"
}

variable "backup_resource_group_name" {
  description = "Resource group to create for backup resources."
  type        = string
  default     = "rg-vm-backup"
}

variable "recovery_vault_name" {
  description = "Globally unique/available Recovery Services Vault name in the subscription."
  type        = string
  default     = "myapp-recovery-vault-001"
}

variable "backup_policy_name" {
  description = "Azure VM backup policy name."
  type        = string
  default     = "daily-vm-backup-policy"
}

variable "backup_time_utc" {
  description = "Daily backup start time in UTC, HH:MM."
  type        = string
  default     = "20:00"
}
