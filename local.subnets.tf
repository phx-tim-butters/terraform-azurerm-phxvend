locals {

  network_security_group_custom_rule_map = { for k, v in var.network_security_groups : "${v.location}-${v.virtual_network_short_name}-${v.resource_name}" => v }

  subnets = merge([
    for vnet_key, vnet in var.virtual_networks : {
      for subnet_key, subnet in vnet.subnets :
      "${vnet_key}-${subnet.name}" => merge(subnet, {

        resource_name             = subnet.name
        location                  = vnet.location
        resource_group_short_name = vnet.resource_group_short_name

        virtual_network_id   = module.vend.virtual_network_resource_ids["${vnet.location}-${vnet.resource_name}"]
        virtual_network_name = vnet.resource_name

        network_security_group_custom_rules = { for v in try(local.network_security_group_custom_rule_map["${vnet.location}-${vnet.resource_name}-${subnet.name}"].rules, []) : v.name => v }
        route_table_id                      = !local.post_run_environment ? try(module.vend.route_table_resource_ids["${vnet.location}-${subnet.route_table_short_name}"], null) : try(var.post_run_resources["route_tables"]["${vnet.location}-${subnet.route_table_short_name}"]["created_resource"].resource_id, null)

        address_prefixes = [subnet.subnet_address_space]

        service_endpoints = [for se in subnet.service_endpoints : {
          service = se
        }]
        delegations                               = subnet.delegation
        private_endpoint_network_policies_enabled = subnet.privateEndpointNetworkPolicies == "Enabled" ? true : false
        nat_gateway = subnet.nat_gateway_id == "" ? null : {
          id = subnet.nat_gateway_id
        }
        default_outbound_access_enabled = subnet.default_outbound_access_enabled
      })
    }
  ]...)
}

module "subnets" {
  source = "./modules/subnet"

  for_each = { for k, v in local.subnets : "${v.location}-${v.virtual_network_name}-${v.resource_name}" => v }

  default_location = try(each.value.location, var.default_location)

  subnet                                  = each.value
  virtual_network_id                      = each.value.virtual_network_id
  network_security_group_custom_rules     = merge(try(each.value.network_security_group_custom_rules, {}), try(var.network_security_group_custom_default_rules, {}))
  network_security_group_name_prefix      = module.naming_post_vend["network_security_group-${each.value.location}-${each.value.virtual_network_name}-${each.value.resource_name}"].name
  network_security_group_creation_enabled = true

  tags = merge(var.default_resource_group_tags, try(each.value.tags, {}))

  depends_on = [
    module.vend
  ]

  module_avm_res_network_virtualnetwork_version = var.module_avm_res_network_virtualnetwork_version
}
