output "resource_outputs" {
  value = {
    resource_groups = { for key, id in module.vend.resource_group_resource_ids : key => merge(
      local.resource_groups[key],
      {
        resource_id = id
      }
    ) }

    virtual_networks = { for key, id in module.vend.virtual_network_resource_ids : key => merge(
      local.virtual_networks[key],
      {
        resource_id = id
      }
    ) }
  }
}
