module "network_security_group" {
  source = "../network_security_group"
  count  = var.network_security_group_creation_enabled && local.create_network_security_group ? 1 : 0

  default_location = var.default_location

  network_security_group_name = "${var.network_security_group_name_prefix}-${var.subnet.resource_name}"
  resource_group_name         = provider::azurerm::parse_resource_id(var.virtual_network_id).resource_group_name

  network_security_group_custom_rules = var.network_security_group_custom_rules

  network_security_group_properties = {
    enable_explicit_inbound_deny  = true
    enable_explicit_outbound_deny = false
    subnet_address_spaces         = var.subnet.address_prefixes
    bastion_subnet_address_spaces = var.bastion_subnet_address_spaces
    subnet_name                   = var.subnet.resource_name
  }

  tags = var.tags
}

# Do logic check here to see if this subnet requires a Network Security Group
locals {
  create_network_security_group = var.network_security_group_creation_enabled && !(strcontains(var.subnet.resource_name, "GatewaySubnet") || strcontains(var.subnet.resource_name, "AzureFirewall")) ? true : false
}

module "subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = var.module_avm_res_network_virtualnetwork_version

  name                              = var.subnet.resource_name
  parent_id                         = var.virtual_network_id
  address_prefixes                  = var.subnet.address_prefixes
  service_endpoints                 = try(toset(var.subnet.service_endpoints), [])
  delegations                       = try(var.subnet.delegations, [])
  private_endpoint_network_policies = try(var.subnet.private_endpoint_network_policies_enabled, false) ? "Enabled" : "Disabled"

  network_security_group = local.create_network_security_group ? {
    id = module.network_security_group[0].resource_id
  } : null

  route_table = try(var.subnet.route_table_id, null) != null ? {
    id = var.subnet.route_table_id
  } : null
}
