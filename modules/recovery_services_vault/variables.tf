variable "name_prefix" {
  type        = string
  description = "Prefix used to build Recovery Services Vault names created by this module (for example suffixes for LRS/GRS/ZRS variants are appended)."
}

variable "vault_resource_group_name" {
  type        = string
  description = "Name of the resource group where Recovery Services Vault resources are created."
}

variable "backup_resource_group_name" {
  type        = string
  description = "Prefix for instant restore resource group naming used by backup policies."
}

variable "location" {
  type        = string
  description = "Azure region where Recovery Services Vault resources are deployed."
}

variable "tags" {
  description = "The map of tags to assign to all created resources."
  default     = {}
  type        = map(string)
}

variable "zonal_region" {
  description = "Whether the deployment region supports zonal vault SKU creation. When true, a ZRS vault variant is also provisioned."
  type        = bool
}

variable "rsv_settings" {
  description = "Policy settings applied to each created Recovery Services Vault, including immutability mode, soft delete, and cross-region restore controls."
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
  description = "Map of custom VM backup policy templates applied to each created vault. Built-in daily/hourly VM and file-share policies are created separately."
  type = map(object({
    name                            = string
    instance_restore_retention_days = number
    backup_frequency = object({
      frequency     = string
      time          = string
      weekdays      = optional(list(string), [])
      hour_interval = optional(number)
      hour_duration = optional(number)
    })
    retention_daily = optional(object({
      count = optional(number)
    }), { count = null })
    retention_weekly = optional(object({
      count    = number
      weekdays = list(string)
    }))
    retention_monthly = optional(object({
      count             = number
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }))
    retention_yearly = optional(object({
      count             = number
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
      }), {
      count             = 0
      months            = []
      weekdays          = []
      weeks             = []
      days              = []
      include_last_days = false
    })
  }))
  default = {}
}
