locals {
  recovery_services_vault_regions = { for location in var.templated_locations : location => {
    resource_name              = ""
    resource_group_short_name  = "bcdr"
    location                   = location
    zonal_region               = lookup(local.zonal_regions, location, false)
    vault_resource_group_name  = local.resource_groups["${location}-bcdr"].name
    backup_resource_group_name = local.resource_groups["${location}-backup"].name
  } }
}

module "recovery_service_vaults" {
  source   = "./modules/recovery_services_vault"
  for_each = local.recovery_services_vault_regions

  name_prefix = module.naming_post_vend["recovery_services_vault-${each.value.location}"].name

  location                   = try(each.value.location, var.default_location)
  zonal_region               = each.value.zonal_region
  vault_resource_group_name  = each.value.vault_resource_group_name
  backup_resource_group_name = each.value.backup_resource_group_name

  rsv_settings = {
    cross_region_restore_enabled = var.rsv_settings.cross_region_restore_enabled
    immutability                 = var.rsv_settings.immutability
    soft_delete_enabled          = var.rsv_settings.soft_delete_enabled
  }

  azure_backup_templated_policies = var.azure_backup_templated_policies

  tags = merge(var.default_resource_group_tags, try(each.value.tags, {}))

  depends_on = [
    module.vend
  ]
}
