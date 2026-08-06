output "resource_outputs" {
  value = {
    resource_groups = { for key, group in local.resource_groups : key => merge(
      group,
      {
        resource_name       = module.naming["resource_group-${group.location}-${group.resource_name}"].name
        resource_group_name = module.naming["resource_group-${group.location}-${group.resource_name}"].resource_group_name
        resource_id         = module.vend.resource_group_resource_ids[key]
      }
    ) }

    virtual_networks = { for key, vnet in local.virtual_networks : key => merge(
      vnet,
      {
        resource_name       = module.naming["virtual_network-${vnet.location}-${vnet.resource_name}"].name
        resource_group_name = module.naming["virtual_network-${vnet.location}-${vnet.resource_name}"].resource_group_name
        resource_id         = module.vend.virtual_network_resource_ids[key]
      }
    ) }
  }
}
