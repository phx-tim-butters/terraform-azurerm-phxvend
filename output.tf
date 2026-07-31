output "resource_outputs" {
  value = {
    resource_groups  = module.vend.resource_group_resource_ids
    virtual_networks = module.vend.virtual_network_resource_ids
  }
}
