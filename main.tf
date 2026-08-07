module "vend" {
  source  = "Azure/avm-ptn-alz-sub-vending/azure"
  version = var.module_avm_ptn_alz_sub_vending_version

  enable_telemetry = false

  # Set the default location for resources
  location = var.default_location

  # subscription variables
  subscription_id              = var.subscription_details.subscription_id
  subscription_alias_enabled   = var.subscription_details.subscription_alias_enabled
  subscription_billing_scope   = var.subscription_details.subscription_billing_scope
  subscription_display_name    = var.subscription_details.subscription_display_name
  subscription_alias_name      = var.subscription_details.subscription_alias_name
  subscription_workload        = var.subscription_details.subscription_workload
  subscription_update_existing = var.subscription_details.subscription_update_existing
  subscription_tags            = var.subscription_details.subscription_tags

  # management group association variables
  subscription_management_group_association_enabled = var.subscription_details.subscription_management_group_association_enabled
  subscription_management_group_id                  = var.subscription_details.subscription_management_group_id

  resource_group_creation_enabled = length(local.resource_groups) > 0 ? true : false
  resource_groups                 = length(local.resource_groups) > 0 ? local.resource_groups : null

  network_security_group_enabled = false

  route_table_enabled = length(local.route_tables) > 0 ? true : false
  route_tables        = length(local.route_tables) > 0 ? local.route_tables : null

  virtual_network_enabled = length(local.virtual_networks) > 0 ? true : false
  virtual_networks        = length(local.virtual_networks) > 0 ? local.virtual_networks : null
}
