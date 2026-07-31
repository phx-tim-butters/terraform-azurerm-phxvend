locals {
  route_tables = { for key, route_table in var.route_tables : "${route_table.location}-${route_table.resource_name}" => merge(
    route_table
    ,
    {
      name     = module.naming["route_table-${route_table.location}-${route_table.resource_name}"].name
      location = try(route_table.location, var.default_location)

      key_name                      = "${route_table.location}-${route_table.resource_name}"
      resource_group_key            = "${route_table.location}-${route_table.resource_group_short_name}"
      bgp_route_propagation_enabled = strcontains(lower(route_table.resource_name), "gatewaysubnet") || strcontains(lower(route_table.resource_name), "azurefirewall") ? true : route_table.bgp_route_propagation_enabled
      tags                          = merge(var.default_resource_group_tags, try(route_table.tags, {}))

      routes = { for route in route_table.routes : route.name => route }
    })
  }
}
