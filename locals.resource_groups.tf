locals {
  resolved_default_resource_group_tags = {
    for group_key, group in var.templated_resource_groups : group_key => {
      for tag_key, tag_value in var.default_resource_group_tags : tag_key =>
      replace(
        replace(tag_value, "*WORK*", var.workload_abbreviation),
        "*ARCH*",
        var.archetype
      )
    }
  }

  // Default Resource Groups to stamp on all areas if not explicitly defined
  default_resource_groups = {
    for key, group in var.templated_resource_groups : key => merge(
      group,
      {
        tags = merge(
          local.resolved_default_resource_group_tags[key],
          {
            for replacement in group.tags_to_replace : replacement.tag_key => replace(
              local.resolved_default_resource_group_tags[key][replacement.tag_key],
              replacement.key_to_replace,
              replacement.value
            ) if contains(keys(local.resolved_default_resource_group_tags[key]), replacement.tag_key)
          }
        )
      }
    )
  }
}

locals {
  // We need to get a list of all locations we're deploying baseline templates to.
  locations = distinct(concat(var.templated_locations, [var.default_location]))
}

locals {
  # Custom Resource Groups fed in
  custom_resource_groups = { for key, group in var.resource_groups : "${group.location}-${group.resource_name}" => merge(
    group,
    {

      lock_enabled              = var.resource_groups_lock_override ? false : group.lock_enabled
      lock_name                 = try(group.lock_name, "CanNotDelete")
      resource_group_short_name = key
    })
  }

  # Resource Groups to be applied to all templated regions
  templated_resource_groups = { for location in local.locations : location => {
    for key, group in local.default_resource_groups : "${location}-${key}" => merge(
      group,
      {
        resource_name             = key
        location                  = location
        resource_group_short_name = key
        lock_enabled              = var.resource_groups_lock_override ? false : group.lock_enabled
        lock_name                 = "CanNotDelete"
        tags = { for key, value in group.tags : key =>
          replace(value, "*LOCATION*", location
        ) }
    })
    }
  }

  # Create a merged list of Resources groups based on; templated resource groups across all templated regions, resource groups just for the default region and any custom resource groups defined in the var.resource_groups variable.
  # This local feeds the naming model to generate a list of names
  resource_groups_merged = merge(
    merge(values(local.templated_resource_groups)...)
    ,
    local.custom_resource_groups
  )

  # Generate a readied list of Resource Groups to pass to vend module, grab the generated name from the naming module. Establish Key name, and final merge of tags.
  resource_groups = {
    for key, group in local.resource_groups_merged : key => merge(
      group,
      {
        name     = module.naming["resource_group-${key}"].name
        key_name = "${group.location}-${group.resource_name}"
        tags     = merge(var.default_resource_group_tags, try(group.tags, {}))
      }
    ) if !local.post_run_environment
  }
}
