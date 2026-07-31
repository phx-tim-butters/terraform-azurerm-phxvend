locals {

  // Here we are specifing what vaults we need per subscription per region
  base_vaults = {
    "lrs" = {
      storage_mode_type = "LocallyRedundant"
    }
    "grs" = {
      storage_mode_type = "GeoRedundant"
    }
  }

  vaults = merge(
    local.base_vaults,
    var.zonal_region ? {
      "zrs" = {
        storage_mode_type = "ZoneRedundant"
      }
  } : {})
}

locals {
  vault_policy_map = merge([
    for vault_key, vault in local.vaults : {
      for policy_key, policy in var.azure_backup_templated_policies :
      "${vault_key}-${policy_key}" => {
        vault_key  = vault_key
        vault      = vault
        policy_key = policy_key
        policy     = policy
      }
    }
  ]...)
}

resource "azurerm_recovery_services_vault" "vault" {
  for_each = local.vaults

  name                = "${var.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = var.vault_resource_group_name
  sku                 = "Standard"
  storage_mode_type   = each.value.storage_mode_type

  public_network_access_enabled = false

  soft_delete_enabled          = var.rsv_settings.soft_delete_enabled
  immutability                 = var.rsv_settings.immutability
  cross_region_restore_enabled = strcontains(each.key, "grs") ? var.rsv_settings.cross_region_restore_enabled : false

  tags = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [tags]
  }

  monitoring {
    alerts_for_all_job_failures_enabled            = true
    alerts_for_critical_operation_failures_enabled = true
  }
}

// Creates a daily VM Backup Policy per Vault 
resource "azurerm_backup_policy_vm" "vm_daily" {
  for_each = local.vaults

  name                = "pol-vm-daily-${each.key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.key].name
  policy_type         = "V2"

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  instant_restore_retention_days = 7

  instant_restore_resource_group {
    prefix = var.backup_resource_group_name
    suffix = null
  }

  retention_daily {
    count = 21
  }
}

// Creates a 4 Hourly VM Backup Policy per Vault 
resource "azurerm_backup_policy_vm" "vm_hour" {
  for_each = local.vaults

  name                = "pol-vm-4hourly-${each.key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.key].name
  policy_type         = "V2"

  timezone = "UTC"

  backup {
    frequency     = "Hourly"
    time          = "23:00"
    hour_interval = 4
    hour_duration = 4
  }

  instant_restore_retention_days = 7

  instant_restore_resource_group {
    prefix = var.backup_resource_group_name
    suffix = null
  }

  retention_daily {
    count = 21
  }
}


resource "azurerm_backup_policy_file_share" "file_daily" {
  for_each = local.vaults

  name                = "pol-file-daily-${each.key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.key].name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 21
  }
}

resource "azurerm_backup_policy_file_share" "file_hourly" {
  for_each = local.vaults

  name                = "pol-file-4hourly-${each.key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.key].name

  timezone = "UTC"

  backup {
    frequency = "Hourly"
    hourly {
      interval        = 4
      start_time      = "00:00"
      window_duration = 23
    }
  }

  retention_daily {
    count = 21
  }
}


resource "azurerm_backup_policy_vm" "custom_daily" {
  for_each = { for k, v in local.vault_policy_map : k => v if v.policy.backup_frequency.frequency == "Daily" }

  name                = "pol-vm-${each.value.policy.name}-${each.value.vault_key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.value.vault_key].name
  policy_type         = "V2"
  timezone            = "UTC"

  backup {
    frequency     = each.value.policy.backup_frequency.frequency
    time          = each.value.policy.backup_frequency.time
    hour_interval = try(each.value.policy.backup_frequency.hour_interval, null)
    hour_duration = try(each.value.policy.backup_frequency.hour_duration, null)
    weekdays      = each.value.policy.backup_frequency.weekdays
  }

  instant_restore_retention_days = each.value.policy.instance_restore_retention_days

  instant_restore_resource_group {
    prefix = var.vault_resource_group_name
    suffix = null
  }

  dynamic "retention_daily" {
    for_each = each.value.policy.retention_daily.count != null ? [each.value.policy.retention_daily] : []
    content {
      count = retention_daily.value.count
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.policy.retention_weekly != null ? [each.value.policy.retention_weekly] : []
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.policy.retention_monthly != null ? [each.value.policy.retention_monthly] : []
    content {
      count    = retention_monthly.value.count
      weekdays = length(retention_monthly.value.weekdays) > 0 ? retention_monthly.value.weekdays : null
      weeks    = length(retention_monthly.value.weeks) > 0 ? retention_monthly.value.weeks : null
      days     = length(retention_monthly.value.days) > 0 ? retention_monthly.value.days : null
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.policy.retention_yearly.count != 0 ? [each.value.policy.retention_yearly] : []
    content {
      count    = retention_yearly.value.count
      months   = length(retention_yearly.value.months) > 0 ? retention_yearly.value.months : null
      weekdays = length(retention_yearly.value.weekdays) > 0 ? retention_yearly.value.weekdays : null
      weeks    = length(retention_yearly.value.weeks) > 0 ? retention_yearly.value.weeks : null
      days     = length(retention_yearly.value.days) > 0 ? retention_yearly.value.days : null
    }
  }
}

resource "azurerm_backup_policy_vm" "custom_non_daily" {
  for_each = { for k, v in local.vault_policy_map : k => v if v.policy.backup_frequency.frequency != "Daily" }

  name                = "pol-vm-${each.value.policy.name}-${each.value.vault_key}"
  resource_group_name = var.vault_resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault[each.value.vault_key].name
  policy_type         = "V2"
  timezone            = "UTC"

  backup {
    frequency = each.value.policy.backup_frequency.frequency
    time      = each.value.policy.backup_frequency.time
    weekdays  = each.value.policy.backup_frequency.weekdays
  }

  instant_restore_retention_days = each.value.policy.instance_restore_retention_days

  instant_restore_resource_group {
    prefix = var.backup_resource_group_name
    suffix = null
  }

  dynamic "retention_weekly" {
    for_each = try(each.value.policy.retention_weekly, null) != null ? [each.value.policy.retention_weekly] : []
    content {
      count    = retention_weekly.value.count
      weekdays = length(retention_weekly.value.weekdays) > 0 ? retention_weekly.value.weekdays : null
    }
  }

  dynamic "retention_monthly" {
    for_each = try(each.value.policy.retention_monthly, null) != null ? [each.value.policy.retention_monthly] : []
    content {
      count = retention_monthly.value.count

      weekdays = retention_monthly.value.include_last_days == false && length(retention_monthly.value.weekdays) > 0 ? retention_monthly.value.weekdays : null
      weeks    = retention_monthly.value.include_last_days == false && length(retention_monthly.value.weeks) > 0 ? retention_monthly.value.weeks : null
      days     = retention_monthly.value.include_last_days == false && length(retention_monthly.value.days) > 0 ? retention_monthly.value.days : null

      include_last_days = retention_monthly.value.include_last_days == true ? true : null
    }
  }

  dynamic "retention_yearly" {
    for_each = try(each.value.policy.retention_yearly, null) != null && each.value.policy.retention_yearly.count > 0 ? [each.value.policy.retention_yearly] : []
    content {
      count  = retention_yearly.value.count
      months = length(retention_yearly.value.months) > 0 ? retention_yearly.value.months : null

      weekdays = retention_yearly.value.include_last_days == false && length(retention_yearly.value.weekdays) > 0 ? retention_yearly.value.weekdays : null
      weeks    = retention_yearly.value.include_last_days == false && length(retention_yearly.value.weeks) > 0 ? retention_yearly.value.weeks : null
      days     = retention_yearly.value.include_last_days == false && length(retention_yearly.value.days) > 0 ? retention_yearly.value.days : null

      include_last_days = retention_yearly.value.include_last_days == true ? true : null
    }
  }
}
