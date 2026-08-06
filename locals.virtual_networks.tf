locals {
  # Because we could potentially create multiple Virtual WANs, but we only want to use the first one for the default vwan_key, we need to get the first key from the virtual_wan_hubs map. This is used in the virtual_networks local to determine which vwan hub to connect to if no vwan_key is specified for a given virtual network.
  default_virtual_wan_key = keys(var.network_topology_details.virtual_wan_hubs)[0]
}

locals {
  virtual_networks = { for key, vnet in var.virtual_networks : "${vnet.location}-${vnet.resource_name}" => {

    name               = module.naming["virtual_network-${vnet.location}-${vnet.resource_name}"].name
    key_name           = "${vnet.location}-${vnet.resource_name}"
    address_space      = vnet.address_space
    resource_group_key = "${vnet.location}-${vnet.resource_group_short_name}"
    location           = vnet.location

    dns_servers = vnet.dns_servers

    hub_peering_options_tohub = {
      use_remote_gateways = var.network_topology_details.create_gateways
    }
    hub_peering_options_fromhub = {
      allow_gateway_transit = var.network_topology_details.create_gateways
    }

    vwan_connection_enabled = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type == "Vwan" ? true : false
    hub_peering_enabled     = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type != "Vwan" && vnet.resource_name != "hub" ? var.network_topology_details.hub_peering_enabled : false

    hub_network_resource_id = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type != "Vwan" ? try(var.network_topology_details.hub_id[vnet.location], null) : null


    vwan_hub_resource_id = var.network_topology_details.hub_peering_enabled && var.network_topology_details.network_type == "Vwan" ? var.network_topology_details.virtual_wan_hubs[try(vnet.vwan_key, local.default_virtual_wan_key)].id : null

    vwan_security_configuration = {
      secure_internet_traffic = true
      routing_intent_enabled  = var.network_topology_details.virtual_wan_hubs[try(vnet.vwan_key, local.default_virtual_wan_key)].routing_intent_enabled
    }

    tags = merge(var.default_resource_group_tags, try(vnet.tags, {}))
    }
  }
}
