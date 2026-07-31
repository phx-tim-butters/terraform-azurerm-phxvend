locals {
  network_security_groups            = { for key, nsg in var.network_security_groups : "${nsg.location}-${nsg.virtual_network_short_name}-${nsg.resource_name}" => nsg if nsg.virtual_network_short_name != "" }
  additional_network_security_groups = { for key, nsg in var.network_security_groups : "${nsg.location}-${nsg.virtual_network_short_name}-${nsg.resource_name}" => nsg if nsg.virtual_network_short_name == "" }
}

module "network_security_group" {
  source   = "./modules/network_security_group"
  for_each = local.additional_network_security_groups

  default_location = try(each.value.location, var.default_location)

  network_security_group_name = module.naming["network_security_group-${each.value.location}-${each.value.resource_group_short_name}-${each.value.resource_name}"].name
  resource_group_name         = module.naming["resource_group-${each.value.location}-${each.value.resource_group_short_name}"].name

  network_security_group_properties = {
    enable_explicit_inbound_deny  = each.value.enable_explicit_inbound_deny
    enable_explicit_outbound_deny = each.value.enable_explicit_outbound_deny
    bastion_subnet_address_spaces = var.network_topology_details.bastion_subnet_address_spaces
  }

  tags = merge(var.default_resource_group_tags, try(each.value.tags, {}))

  depends_on = [
    module.vend,
  ]
}
