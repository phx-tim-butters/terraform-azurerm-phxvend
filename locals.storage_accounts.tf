locals {
  default_storage_accounts = {
    flow = {
      resource_group_short_name = "storage"
      account_sku_name          = "Standard_LRS"
      shared_access_key_enabled = true
      tags = merge({ for key, value in var.default_resource_group_tags : key => replace(replace(value, "*GROUPNAME*", "Storage Resources"), "*ARCH*", var.archetype) },
        {
          Application = "*LOCATION* Flow Log Storage Account"
      })
    }
  }

  // Default Resource Groups to stamp on all areas if not explicitly defined
  templated_storage_accounts = { for location in local.locations : location => {
    for key, st in local.default_storage_accounts : "${location}-${key}" => {
      resource_name             = key
      resource_group_short_name = st.resource_group_short_name
      location                  = location
      account_sku_name          = st.account_sku_name
      shared_access_key_enabled = st.shared_access_key_enabled
      network_rules = {
        creator_ip_rule = false
        default_action  = "Deny"
        bypass          = ["AzureServices"]
      }
      tags = { for key, value in st.tags : key => replace(value, "*LOCATION*", location) }
    }
    }
  }

  # Create a merged map of all Storage Accounts based on; templated storage accounts across all templated regions, and any custom storage accounts defined in the var.storage_accounts variable.
  # This feeds the naming model to generate a list of names for the storage accounts.
  storage_accounts_merged = merge(
    merge(values(local.templated_storage_accounts)...)
    ,
    var.storage_accounts
  )

  # Generate a readied list of Storage Accounts to pass to vend module, grab the generated name from the naming module. Establish Key name, and final merge of tags.
  storage_accounts = { for key, st in local.storage_accounts_merged : key => merge(
    st,
    {
      name     = module.naming["storage_account-${st.location}-${st.resource_name}"].global_name
      key_name = "${st.location}-${st.resource_name}"
    }
    ) if !local.post_run_environment
  }
}


module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = var.module_avm_res_storage_storageaccount_version

  for_each = local.storage_accounts

  location  = each.value.location
  name      = each.value.name
  parent_id = module.vend.resource_group_resource_ids["${each.value.location}-${each.value.resource_group_short_name}"]

  enable_telemetry = false

  account_sku_name = each.value.account_sku_name

  shared_access_key_enabled       = each.value.shared_access_key_enabled
  public_network_access_enabled   = each.value.network_rules["default_action"] == "Deny" ? false : true
  allow_nested_items_to_be_public = each.value.network_rules["default_action"] == "Deny" ? false : true

  network_rules = {
    bypass         = each.value.network_rules["bypass"]
    default_action = each.value.network_rules["default_action"]
    ip_rules       = each.value.network_rules["creator_ip_rule"] ? var.paas_allowed_ip_addresses : null
  }

  tags = each.value.tags
}

