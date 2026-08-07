locals {
  resources = merge(

    # Construct Namings for Resource Groups
    { for k, v in local.resource_groups_merged : "resource_group-${v.location}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type         = "resource_group"
        workload_abbreviation = try(v.workload_abbreviation, var.workload_abbreviation)
        archetype             = try(v.archetype, var.archetype)
      })
    }
    ,
    # Construct Namings for Additional Network Security Groups not tied to a subnet
    { for k, v in local.default_region_resource_groups : "network_security_group-${v.location}-${v.resource_group_short_name}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type         = "network_security_group"
        workload_abbreviation = try(v.workload_abbreviation, var.workload_abbreviation)
        archetype             = try(v.archetype, var.archetype)
      })
    }
    ,
    # Construct Namings for Route Tables
    { for k, v in var.route_tables : "route_table-${v.location}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type         = "route_table"
        workload_abbreviation = try(v.workload_abbreviation, var.workload_abbreviation)
        archetype             = try(v.archetype, var.archetype)
      })
    }
    ,
    # Construct Namings for Virtual Networks
    { for k, v in var.virtual_networks : "virtual_network-${v.location}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type         = "virtual_network"
        workload_abbreviation = try(v.workload_abbreviation, var.workload_abbreviation)
        archetype             = try(v.archetype, var.archetype)
      })
    }
    ,
    # Construct Namings for Storage Accounts
    { for k, v in local.storage_accounts : "storage_account-${v.location}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type         = "storage_account"
        workload_abbreviation = try(v.workload_abbreviation, var.workload_abbreviation)
        archetype             = try(v.archetype, var.archetype)
      }
      )
    }
  )
}



# For generated list of Resources within this module, generate all names
module "naming" {
  source   = "phx-tim-butters/phxnaming/azurerm"
  version  = "0.1.7"
  for_each = local.resources

  archetype             = try(each.value.workload, var.archetype)
  workload_abbreviation = try(each.value.workload, var.workload_abbreviation)
  org_abbreviation      = var.org_abbreviation
  env_abbreviation      = try(each.value.environment, var.deploy_abbreviation)
  structure             = try(each.value.structure, var.structure)
  deploy_abbreviation   = var.deploy_abbreviation
  location              = each.value.location

  resource_type           = each.value.resource_type
  resource_name           = each.value.resource_name
  resource_name_overwrite = try(each.value.resource_name_overwrite, false)

  resource_group_name           = each.value.resource_group_short_name
  resource_group_name_overwrite = try(each.value.resource_group_name_overwrite, false)

  case_option = try(each.value.case_option, "lower")
}

locals {
  post_vend_naming = merge(
    { for k, v in local.subnets : "network_security_group-${v.location}-${v.resource_group_short_name}-${v.resource_name}" => merge(
      v
      ,
      {
        resource_type = "network_security_group"
        structure     = join("-", [for p in split("-", var.structure) : p if lower(p) != "name"])
      })
    }
    ,
    # Construct Namings for Recovery Services Vaults, which are templated on a per region/per environment basis. This creates a prefix that is applied to the RSV resilience (LRS, GRS etc...).
    # Alter the structure to remove the name element, as we want a prefix to pass to the module to create the RSVs with a suffix of LRS, GRS etc... to be added to the end of the name.
    { for k, v in local.recovery_services_vault_regions : "recovery_services_vault-${v.location}" => merge(
      v
      ,
      {
        resource_type = "recovery_services_vault"
        structure     = join("-", [for p in split("-", var.structure) : p if lower(p) != "name"])
      })
    }
  )
}


# As we need to also name the NSGs for any subsequent Subnets that get created which depends on vending already completed - we need to shout up to the Naming module seperately on a per subnet basis to not get cycle dependancy.
module "naming_post_vend" {
  source   = "phx-tim-butters/phxnaming/azurerm"
  version  = "0.1.7"
  for_each = local.post_vend_naming

  archetype             = try(each.value.workload, var.archetype)
  workload_abbreviation = try(each.value.workload, var.workload_abbreviation)
  org_abbreviation      = var.org_abbreviation
  env_abbreviation      = try(each.value.environment, var.deploy_abbreviation)
  structure             = try(each.value.structure, var.structure)
  deploy_abbreviation   = var.deploy_abbreviation
  location              = each.value.location

  resource_type           = each.value.resource_type
  resource_name           = each.value.resource_name
  resource_name_overwrite = try(each.value.resource_name_overwrite, false)

  resource_group_name           = each.value.resource_group_short_name
  resource_group_name_overwrite = try(each.value.resource_group_name_overwrite, false)

  case_option = try(each.value.case_option, "lower")
}

