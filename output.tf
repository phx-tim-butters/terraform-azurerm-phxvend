output "resource_outputs" {
  value = {
    resource_groups = { for key, group in local.resource_groups : key => merge(
      group,
      {
        created_resource = {
          resource_name       = module.naming["resource_group-${group.key_name}"].name
          resource_group_name = module.naming["resource_group-${group.key_name}"].resource_group_name
          resource_id         = module.vend.resource_group_resource_ids[key]
        }
      }
    ) }

    virtual_networks = { for key, vnet in local.virtual_networks : key => merge(
      vnet,
      {
        created_resource = {
          resource_name       = module.naming["virtual_network-${vnet.key_name}"].name
          resource_group_name = module.naming["virtual_network-${vnet.key_name}"].resource_group_name
          resource_id         = module.vend.virtual_network_resource_ids[key]
        }
      }
    ) }
    route_tables = { for key, rt in local.route_tables : key => merge(
      rt,
      {
        created_resource = {
          resource_name       = module.naming["route_table-${rt.key_name}"].name
          resource_group_name = module.naming["route_table-${rt.key_name}"].resource_group_name
          resource_id         = module.vend.route_table_resource_ids[key]
        }
      }
    ) }
  }
}
