locals {
  default_storage_accounts = {
    flow = {
      resource_group_short_name = "storage"
      account_replication_type  = "LRS"
      access_tier               = "Hot"
      account_tier              = "Standard"
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
      account_replication_type  = st.account_replication_type
      access_tier               = st.access_tier
      account_tier              = st.account_tier
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

  storage_accounts = merge(merge(values(local.templated_storage_accounts)...), var.storage_accounts)
}

module "storage_account" {
  source   = "Azure/avm-res-storage-storageaccount/azurerm"
  version  = var.module_avm_res_storage_storageaccount_version
  for_each = local.storage_accounts

  location            = each.value.location
  name                = module.naming["storage_account-${each.value.location}-${each.value.resource_name}"].global_name
  resource_group_name = module.naming["resource_group-${each.value.location}-${each.value.resource_group_short_name}"].name
  enable_telemetry    = false

  access_tier                     = each.value.access_tier
  account_replication_type        = each.value.account_replication_type
  account_tier                    = each.value.account_tier
  shared_access_key_enabled       = each.value.shared_access_key_enabled
  public_network_access_enabled   = each.value.network_rules["default_action"] == "Deny" ? false : true
  allow_nested_items_to_be_public = each.value.network_rules["default_action"] == "Deny" ? false : true

  network_rules = {
    bypass         = each.value.network_rules["bypass"]
    default_action = each.value.network_rules["default_action"]
    ip_rules       = each.value.network_rules["creator_ip_rule"] ? var.paas_allowed_ip_addresses : null
  }

  tags = each.value.tags

  depends_on = [
    module.vend,
  ]
}

