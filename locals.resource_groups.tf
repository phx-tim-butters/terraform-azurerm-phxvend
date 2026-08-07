locals {
  // Default Resource Groups to stamp on all areas if not explicitly defined
  default_resource_groups = {
    network = {
      tags                = { for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "Network Resources"), "*ARCH*", var.archetype) }
      default_region_only = false
      lock_enabled        = true
    }
    security = {
      tags                = { for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "Security Resources"), "*ARCH*", var.archetype) }
      default_region_only = false
      lock_enabled        = true
    }
    storage = {
      tags                = { for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "Storage Resources"), "*ARCH*", var.archetype) }
      default_region_only = false
      lock_enabled        = true
    }
    bcdr = {
      tags                = { for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "BCDR Resources"), "*ARCH*", var.archetype) }
      default_region_only = false
      lock_enabled        = true
    }
    backup = {
      tags                = { for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "Backup Resources"), "*ARCH*", var.archetype) }
      default_region_only = false
      lock_enabled        = false
    }
  }
}

locals {
  // We need to get a list of all locations we're deploying baseline templates to. so grab the default location and also get any templated deployed locations to produce a set of strings.
  locations = distinct(concat(var.templated_locations, formatlist(var.default_location)))
}

locals {
  # Custom Resource Groups fed in
  custom_resource_groups = { for key, group in var.resource_groups : "${group.location}-${group.resource_name}" => merge(
    group,
    {
      lock_enabled              = var.resource_groups_lock_override ? false : group.lock_enabled
      resource_group_short_name = key
    })
  }

  # Resource Groups to be applied to all templated regions
  templated_resource_groups = { for location in local.locations : location => {
    for key, group in local.default_resource_groups : "${location}-${key}" => merge(
      group,
      {
        resource_name             = key
        location                  = try(group.location, var.default_location)
        resource_group_short_name = key
        lock_enabled              = var.resource_groups_lock_override ? false : group.lock_enabled
        lock_name                 = "CanNotDelete"
        tags                      = { for key, value in group.tags : key => replace(value, "*LOCATION*", location) }
    }) if !group.default_region_only
    }
  }

  # Resource Groups to be applied JUST to the default region
  default_region_resource_groups = { for key, group in local.default_resource_groups : "${var.default_location}-${key}" => merge(
    group,
    {
      resource_name             = key
      location                  = try(group.location, var.default_location)
      resource_group_short_name = key
      lock_enabled              = var.resource_groups_lock_override ? false : group.lock_enabled
      lock_name                 = "CanNotDelete"
      tags                      = { for key, value in group.tags : key => replace(value, "*LOCATION*", var.default_location) }
    }) if group.default_region_only
  }

  # Create a merged list of Resources groups based on; templated resource groups across all templated regions, resource groups just for the default region and any custom resource groups defined in the var.resource_groups variable.
  # This local feeds the naming model to generate a list of names
  resource_groups_merged = merge(
    merge(values(local.templated_resource_groups)...)
    ,
    local.default_region_resource_groups
    ,
    local.custom_resource_groups
  )

  # Generate a readied list of Resource Groups to pass to vend module, grab the generated name from the naming module. Establish Key name, and final merge of tags.
  resource_groups = { for key, group in local.resource_groups_merged : key => merge(
    group,
    {
      name     = module.naming["resource_group-${key}"].name
      key_name = "${group.location}-${group.resource_name}"
      tags     = merge(var.default_resource_group_tags, try(group.tags, {}))
    })
  }
}
