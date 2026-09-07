variable "default_location" {
  type        = string
  description = "Default location for resources if not explicitly defined"
}

variable "templated_locations" {
  type        = list(string)
  description = "List of locations to deploy templated resources to"
  default     = []
}

variable "subscription_details" {
  type = object({
    subscription_alias_enabled                            = optional(bool, false)
    subscription_alias_name                               = optional(string, null)
    subscription_billing_scope                            = optional(string, null)
    subscription_display_name                             = string
    subscription_id                                       = string
    subscription_management_group_association_enabled     = optional(bool, false)
    subscription_management_group_id                      = optional(string, null)
    subscription_register_resource_providers_and_features = optional(map(set(string)), {})
    subscription_register_resource_providers_enabled      = optional(bool, false)
    subscription_tags                                     = optional(map(string), {})
    subscription_update_existing                          = optional(bool, false)
    subscription_workload                                 = optional(string, null)
  })
  description = "Subscription vending and governance settings consumed by the ALZ subscription vending module, including alias, billing scope, tags, and management group association options."
}

variable "network_topology_details" {
  description = "Global network topology switches for this environment, including hub peering behavior, gateway usage, and optional Virtual WAN hub mappings."
  type = object({
    network_type                  = optional(string, "")
    create_gateways               = optional(bool, false)
    create_vwan                   = optional(bool, false)
    hub_peering_enabled           = optional(bool, true)
    hub_id                        = optional(map(string), {})
    virtual_wan_hubs              = optional(map(any), {})
    bastion_subnet_address_spaces = optional(list(string), [])
  })
  default = {
    network_type                  = ""
    create_gateways               = false
    create_vwan                   = false
    hub_id                        = {}
    virtual_wan_hubs              = {}
    bastion_subnet_address_spaces = []
  }
}

variable "resource_groups_lock_override" {
  description = "When true, disables lock creation for all resource groups, regardless of per-group lock settings."
  type        = bool
  default     = false
}

variable "default_resource_group_tags" {
  description = "Default tag map applied to templated resources and merged with resource-specific tags. Supports token replacement in local templating logic."
  default     = {}
  type        = map(string)
}

variable "rsv_settings" {
  description = "Settings for the Recovery Services Vault"
  type = object({
    immutability                 = optional(string, "Disabled")
    soft_delete_enabled          = optional(bool, true)
    cross_region_restore_enabled = optional(bool, false)
  })
  default = {
    cross_region_restore_enabled = false
    immutability                 = "Disabled"
    soft_delete_enabled          = true
  }
}

variable "resource_groups" {
  description = "Map of custom resource groups to merge with templated baseline resource groups. Keys are logical short names used by dependent resources."
  type = map(
    object({
      resource_name           = string
      resource_name_overwrite = optional(bool, false) // Should the resource name circumvent the naming standards, if so, the resource will be named as per resource_name.
      location                = string
      lock_enabled            = optional(bool, true) // Should this resource group have a lock applied to it?
      lock_name               = optional(string, "")
      tags                    = optional(map(string), {})
    })
  )
  default = {}
}

variable "virtual_networks" {
  description = "Map of virtual networks and their subnet/peering definitions. Each entry is transformed into vend-ready VNet and subnet configuration."
  type = map(
    object({
      resource_name                      = string
      resource_group_short_name          = string
      existing_resource_group_short_name = optional(string, null)
      location                           = string
      address_space                      = list(string)
      dns_servers                        = optional(list(string), [])
      enable_nat_gw                      = optional(bool, false)
      hub_connection                     = optional(bool, false)
      subnets = list(
        object({
          route_table_short_name          = optional(string, "")
          nsg_short_name                  = optional(string, "")
          name                            = string
          privateEndpointNetworkPolicies  = optional(string, "Enabled")
          subnet_address_space            = string
          service_endpoints               = optional(list(string), [])
          nat_gateway_id                  = optional(string, "")
          default_outbound_access_enabled = optional(bool, false)
          delegation = optional(list(object({
            name = string
            service_delegation = object({
              name    = string
              actions = optional(list(string))
            })
          })), [])
        })
      )
      peerings = optional(list(object({
        resource_name                         = string
        remote_vnet_resource_group_short_name = string
        remote_vnet_environment               = string
        remote_vnet_region                    = string
        remote_vnet_short_name                = string
        remote_vnet_subscription_id           = string
      })), [])
      tags = optional(map(string), {})
    })
  )
  default = {}
}

variable "route_tables" {
  description = "Map of route tables and routes to create and associate with subnets. Route table keys are composed into location-aware resource identifiers."
  type = map(
    object({
      resource_name                      = string
      resource_group_short_name          = string
      existing_resource_group_short_name = optional(string, null)
      location                           = string
      bgp_route_propagation_enabled      = bool
      routes = optional(list(
        object({
          name                   = string
          address_prefix         = string
          next_hop_type          = string
          next_hop_in_ip_address = optional(string, "")
      })), [])
      tags = optional(map(string), {})
    })
  )
  default = {}
}

variable "existing_resource_groups" {
  type    = map(any)
  default = {}
}

variable "network_security_groups" {
  description = "Map of per-subnet NSG custom rule packs"
  type = map(object({
    resource_name                      = string
    resource_group_short_name          = string
    existing_resource_group_short_name = optional(string, null)
    virtual_network_short_name         = optional(string, "")
    location                           = string
    enable_explicit_inbound_deny       = optional(bool, true)
    enable_explicit_outbound_deny      = optional(bool, false)
    rules = optional(list(
      object({
        name                         = string
        access                       = string
        direction                    = string
        description                  = string
        priority                     = number
        protocol                     = string
        source_address_prefixes      = list(string)
        destination_address_prefixes = list(string)
        source_port_ranges           = list(string)
        destination_port_ranges      = list(string)
    })), [])
  }))
  default = {}
}

variable "network_security_group_custom_default_rules" {
  description = "A map of any custom default network security group rules to include in all subnets"
  type = map(object({
    name                         = string
    access                       = string
    direction                    = string
    description                  = string
    priority                     = number
    protocol                     = string
    source_address_prefixes      = list(string)
    destination_address_prefixes = list(string)
    source_port_ranges           = list(string)
    destination_port_ranges      = list(string)
  }))
  default = {}
}

variable "recovery_services_vault" {
  description = "Legacy placeholder for Recovery Services Vault configuration. Retained for backward compatibility; use rsv_settings and azure_backup_templated_policies for active behavior."
  type        = map(any)
  default     = {}
}

variable "storage_accounts" {
  description = "Map of custom storage accounts to merge with templated baseline storage accounts (for example flow log storage), including network rule behavior."
  type = map(object({
    resource_name                      = string
    resource_group_short_name          = string
    existing_resource_group_short_name = optional(string, null)
    location                           = string
    account_sku_name                   = string
    shared_access_key_enabled          = bool
    network_rules = object({
      creator_ip_rule = bool
      default_action  = string
      bypass          = list(string)
    })
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "bastion_address_spaces" {
  description = "List of CIDR ranges used for Azure Bastion. Used by NSG rule logic where Bastion-aware rules are required."
  type        = list(string)
  default     = [""]
}

variable "paas_allowed_ip_addresses" {
  description = "List of allowed public IP CIDR entries used when storage account network rules enable creator IP rule behavior."
  type        = list(string)
  default     = []
}

variable "azure_backup_templated_policies" {
  description = "Map of custom Azure Backup policy templates applied to each created Recovery Services Vault variant (LRS/GRS/ZRS where applicable)."
  type = map(object({
    name                            = string
    instance_restore_retention_days = number
    backup_frequency = object({
      frequency     = string
      time          = string
      weekdays      = optional(list(string), [])
      hour_interval = optional(number)
      hour_duration = optional(number)
    })
    retention_daily = optional(object({
      count = optional(number)
    }), { count = null })
    retention_weekly = optional(object({
      count    = number
      weekdays = list(string)
    }))
    retention_monthly = optional(object({
      count             = number
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }))
    retention_yearly = optional(object({
      count             = number
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
      }), {
      count             = 0
      months            = []
      weekdays          = []
      weeks             = []
      days              = []
      include_last_days = false
    })
  }))
  default = {}
}
