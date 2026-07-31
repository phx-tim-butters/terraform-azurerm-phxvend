locals {
  virtual_networks = { for key, vnet in var.virtual_networks : "${vnet.location}-${vnet.resource_name}" => {

    name               = module.naming["virtual_network-${vnet.location}-${vnet.resource_name}"].name
    key_name           = "${vnet.location}-${vnet.resource_name}"
    address_space      = vnet.address_space
    resource_group_key = "${vnet.location}-${vnet.resource_group_short_name}"
    location           = vnet.location

    dns_servers = vnet.dns_servers

    hub_peering_options_tohub = {
      use_remote_gateways = var.network_topology_details.gw_enabled
    }
    hub_peering_options_fromhub = {
      allow_gateway_transit = var.network_topology_details.gw_enabled
    }

    vwan_connection_enabled = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type == "Vwan" ? true : false
    hub_peering_enabled     = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type != "Vwan" && vnet.resource_name != "hub" ? var.network_topology_details.hub_peering_enabled : false

    hub_network_resource_id = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type != "Vwan" ? try(var.network_topology_details.hub_id[vnet.location], null) : null
    vwan_hub_resource_id    = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type == "Vwan" ? var.network_topology_details.vwan_hub_id[vnet.location] : null

    vwan_security_configuration = {
      secure_internet_traffic = true
      routing_intent_enabled  = var.network_topology_details.vwan_routing_intent_enabled
    }

    tags = merge(var.default_resource_group_tags, try(vnet.tags, {}))
    }
  }
}
