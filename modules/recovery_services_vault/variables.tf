variable "name_prefix" {
  type = string
  description = "Name prefix given to all created vaults within vend"
}

variable "vault_resource_group_name" {
  type = string
  description = "Resource Group Name for the Vault"
}

variable "backup_resource_group_name" {
  type = string
  description = "Resource Group Name for Backup Points (prefix)"
}

variable "location" {
  type        = string
  description = "The location of the vault"
}

variable "tags" {
  description = "The map of tags to assign to all created resources."
  default     = {}
  type        = map(string)
}

variable "zonal_region" {
  description = "Indicates if the region is a zonal region"
  type        = bool
}

variable "rsv_settings" {
  description = "Settings for the Recovery Services Vault"
  type = object({
    immutability                 = optional(string, "Disabled")
    soft_delete_enabled          = optional(bool, true)
    cross_region_restore_enabled = optional(bool, false)
  })
  default = {
    cross_region_restore_enabled = false
    immutability                 = "Disabled"
    soft_delete_enabled          = true
  }
}

variable "azure_backup_templated_policies" {
  description = "A map of templated Azure Backup Policies to apply to the Recovery Services Vault"
  default     = {}
}
