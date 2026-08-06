# terraform-azurerm-vend

A Terraform wrapper module from Phoenix Software that vends a baseline Azure environment using Azure Verified Modules (AVM), opinionated security defaults, and Phoenix naming standards.

This module is designed for repeatable environment vending across subscriptions, with optional subscription alias vending, templated multi-region deployment, and per-environment configuration.

## Intent

This module provides an opinionated platform baseline rather than exposing every AVM switch directly. It focuses on:

- Subscription-aware environment vending (including optional subscription alias flows)
- Consistent naming via the Phoenix naming module
- Templated baseline resource groups and storage per region
- Standardised virtual network, subnet, NSG, and route table composition
- Recovery Services Vault deployment with baseline and optional custom backup policies

## What This Module Deploys

At root level, the module composes:

- Azure ALZ Subscription Vending pattern module:
  - Azure/avm-ptn-alz-sub-vending/azure (version 0.2.1)
- Storage Accounts:
  - Azure/avm-res-storage-storageaccount/azurerm (version 0.6.3)
- Subnets:
  - Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet (version 0.19.0)
- Network Security Groups:
  - Azure/avm-res-network-networksecuritygroup/azurerm (version 0.5.1)
- Phoenix naming:
  - phx-tim-butters/phxnaming/azurerm (version 0.1.4)

It also includes local wrapper logic to:

- Generate baseline resource groups in templated locations:
  - network
  - security
  - storage
  - bcdr
  - backup
- Create default flow-log storage accounts per templated location
- Create and attach subnet NSGs with default and custom rules
- Create standalone NSGs where needed
- Create Recovery Services Vaults and associated backup policies per templated location

## Design Principles

- AVM-first composition with wrapper defaults
- Secure-by-default networking policy posture
- Consistent, organisation-led naming
- Repeatable environment templates with optional local overrides

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm provider | > 4 |

## Providers

| Name | Version |
|------|---------|
| azurerm | > 4 |

## Inputs

The module accepts a broad set of inputs. The table below documents the root interface.

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| tenant_id | string | yes | n/a | Tenant ID for the Azure environment. |
| subscription_details | object | yes | n/a | Subscription metadata and behaviour for vending and association. |
| default_location | string | yes | n/a | Default location for resources not explicitly located. |
| templated_locations | list(string) | no | [] | Additional locations used for templated baseline resources. |
| structure | string | yes | n/a | Naming structure pattern passed to Phoenix naming module. |
| org_abbreviation | string | yes | n/a | Organisation abbreviation for naming. |
| deploy_abbreviation | string | no | "" | Deployment suffix for naming. |
| archetype | string | no | "" | Archetype segment used by naming. |
| workload_abbreviation | string | no | "" | Workload segment used by naming. |
| environment | string | no | "" | Optional environment identifier for naming pattern support. |
| network_topology_details | object | no | see variables.tf defaults | Network topology options (hub peering, vWAN, gateway behaviour, bastion subnet spaces). |
| resource_groups_lock_override | bool | no | false | Global override to disable configured resource group locks. |
| default_resource_group_tags | map(string) | no | {} | Tags merged into templated and custom resources. |
| resource_groups | map(object) | no | {} | Custom resource group definitions merged with templated baseline groups. |
| virtual_networks | map(object) | no | {} | VNet definitions including subnet and peering objects. |
| route_tables | map(object) | no | {} | Route table definitions and route entries. |
| network_security_groups | map(object) | no | {} | NSGs, including subnet-attached and standalone NSG scenarios. |
| network_security_group_custom_default_rules | map(object) | no | {} | NSG rules merged into all subnet NSGs by default. |
| storage_accounts | map(object) | no | {} | Custom storage account definitions merged with templated defaults. |
| paas_allowed_ip_addresses | list(string) | no | [] | Optional IP rules used when creator_ip_rule is enabled for storage network rules. |
| rsv_settings | object | no | see variables.tf defaults | Recovery Services Vault settings including soft delete and immutability. |
| azure_backup_templated_policies | map(object) | no | {} | Custom backup policy templates applied per created vault. |
| recovery_services_vault | map(any) | no | {} | Legacy placeholder; retained for compatibility. |
| bastion_address_spaces | list(string) | no | [""] | List of Bastion subnet CIDRs for rule logic. |

Notes on key object inputs:

- subscription_details supports:
  - subscription_alias_enabled
  - subscription_alias_name
  - subscription_billing_scope
  - subscription_display_name
  - subscription_id
  - subscription_management_group_association_enabled
  - subscription_management_group_id
  - subscription_register_resource_providers_and_features
  - subscription_register_resource_providers_enabled
  - subscription_tags
  - subscription_update_existing
  - subscription_workload
- See variables.tf for full nested object contracts.

## Outputs

| Name | Description |
|------|-------------|
| resource_outputs | Map containing resource group and virtual network resource IDs from the vending module. |

## Usage

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_details.subscription_id
}

module "vend" {
  source = "<ORG>/vend/azurerm"

  tenant_id            = var.tenant_id
  subscription_details = var.subscription_details
  default_location     = "uksouth"
  templated_locations  = ["uksouth", "ukwest"]

  org_abbreviation      = "phx"
  workload_abbreviation = "platform"
  structure             = "TYPE-ORG-REGION-WORK-NAME"

  default_resource_group_tags = {
    Service = "platform-vend"
    Owner   = "platform-team"
  }

  network_topology_details = {
    network_type        = "Vnet-gw"
    gw_enabled          = false
    hub_peering_enabled = false
    hub_id              = {}
    vwan_hub_id         = {}
  }

  virtual_networks = {
    spoke = {
      resource_name             = "spoke"
      resource_group_short_name = "network"
      location                  = "uksouth"
      address_space             = ["10.64.16.0/20"]
      dns_servers               = ["10.7.4.4", "10.7.4.5"]
      subnets = [
        {
          name                            = "snet-app"
          subnet_address_space            = "10.64.16.0/23"
          privateEndpointNetworkPolicies  = "Enabled"
          service_endpoints               = []
          nat_gateway_id                  = ""
          default_outbound_access_enabled = false
        }
      ]
      peerings = []
      tags     = {}
    }
  }

  route_tables = {}
  network_security_groups = {}
}
```

## Behavioural Notes

- Subscription vending is driven by subscription_details and delegated to the ALZ subscription vending AVM pattern module.
- Route table BGP propagation is forced on for route tables whose resource_name contains GatewaySubnet or AzureFirewall.
- Root-level network_security_group_enabled is intentionally disabled for the ALZ vend module; NSGs are managed by this wrapper for subnet and additional NSG scenarios.
- Recovery Services Vaults are created per templated location with LRS and GRS variants, plus ZRS where the region is marked zonal in local.zonal_regions.
- Storage accounts default to public network access disabled when default_action is Deny.

## Examples

- Full environment example: examples/full-env/example.tf
- Standalone NSG example: examples/nsg/example.tf
- Subnet module example: examples/subnets/example.tf

## Validation

Typical local validation workflow:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

## Known Limitations

- local.zonal_regions currently includes a small explicit map and may require extension for additional regions.
- recovery_services_vault input is retained as a legacy placeholder and is not currently used to control deployment.
- Some naming and region-templating assumptions are opinionated for Phoenix vended-environment patterns.

## Contributing

1. Create or update example configurations in examples.
2. Run fmt, validate, and plan before creating a release tag.
3. Update CHANGELOG.md for user-visible changes.

## Publishing To Terraform Registry

Before release:

1. Ensure README.md and LICENSE are present.
2. Ensure examples remain valid.
3. Tag using semantic versioning, for example v0.1.0.
4. Publish from the tagged commit.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | > 4 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_naming"></a> [naming](#module\_naming) | phx-tim-butters/phxnaming/azurerm | 0.1.4 |
| <a name="module_naming_post_vend"></a> [naming\_post\_vend](#module\_naming\_post\_vend) | phx-tim-butters/phxnaming/azurerm | 0.1.4 |
| <a name="module_network_security_group"></a> [network\_security\_group](#module\_network\_security\_group) | ./modules/network_security_group | n/a |
| <a name="module_recovery_service_vaults"></a> [recovery\_service\_vaults](#module\_recovery\_service\_vaults) | ./modules/recovery_services_vault | n/a |
| <a name="module_storage_account"></a> [storage\_account](#module\_storage\_account) | Azure/avm-res-storage-storageaccount/azurerm | 0.6.3 |
| <a name="module_subnets"></a> [subnets](#module\_subnets) | ./modules/subnet | n/a |
| <a name="module_vend"></a> [vend](#module\_vend) | Azure/avm-ptn-alz-sub-vending/azure | 0.2.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_archetype"></a> [archetype](#input\_archetype) | Archetype or workload type used in the ARCH placeholder (e.g., 'web', 'db', 'api'). Helps identify the purpose of the resource. | `string` | `""` | no |
| <a name="input_azure_backup_templated_policies"></a> [azure\_backup\_templated\_policies](#input\_azure\_backup\_templated\_policies) | A map of templated Azure Backup Policies to apply to the Recovery Services Vault | <pre>map(object({<br/>    name                            = string<br/>    instance_restore_retention_days = number<br/>    backup_frequency = object({<br/>      frequency     = string<br/>      time          = string<br/>      weekdays      = optional(list(string), [])<br/>      hour_interval = optional(number)<br/>      hour_duration = optional(number)<br/>    })<br/>    retention_daily = optional(object({<br/>      count = optional(number)<br/>    }), { count = null })<br/>    retention_weekly = optional(object({<br/>      count    = number<br/>      weekdays = list(string)<br/>    }))<br/>    retention_monthly = optional(object({<br/>      count             = number<br/>      weekdays          = optional(list(string), [])<br/>      weeks             = optional(list(string), [])<br/>      days              = optional(list(number), [])<br/>      include_last_days = optional(bool, false)<br/>    }))<br/>    retention_yearly = optional(object({<br/>      count             = number<br/>      months            = optional(list(string), [])<br/>      weekdays          = optional(list(string), [])<br/>      weeks             = optional(list(string), [])<br/>      days              = optional(list(number), [])<br/>      include_last_days = optional(bool, false)<br/>      }), {<br/>      count             = 0<br/>      months            = []<br/>      weekdays          = []<br/>      weeks             = []<br/>      days              = []<br/>      include_last_days = false<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_bastion_address_spaces"></a> [bastion\_address\_spaces](#input\_bastion\_address\_spaces) | List of all Bastion IP Address Ranges | `list(string)` | <pre>[<br/>  ""<br/>]</pre> | no |
| <a name="input_default_location"></a> [default\_location](#input\_default\_location) | Default location for resources if not explicitly defined | `string` | n/a | yes |
| <a name="input_default_resource_group_tags"></a> [default\_resource\_group\_tags](#input\_default\_resource\_group\_tags) | A map of strings that dictate the default templated resource group tagging | `map(string)` | `{}` | no |
| <a name="input_deploy_abbreviation"></a> [deploy\_abbreviation](#input\_deploy\_abbreviation) | Deployment-specific suffix appended to the end of the resource name (e.g., '001', 'blue', 'green'). Useful for blue-green deployments or numbered instances. Optional. | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment identifier used in the ENV placeholder (e.g., 'prod', 'dev', 'test', 'uat', 'nonprod'). Optional, leave empty if not using ENV in your structure. | `string` | `""` | no |
| <a name="input_network_security_group_custom_default_rules"></a> [network\_security\_group\_custom\_default\_rules](#input\_network\_security\_group\_custom\_default\_rules) | A map of any custom default network security group rules to include in all subnets | <pre>map(object({<br/>    name                         = string<br/>    access                       = string<br/>    direction                    = string<br/>    description                  = string<br/>    priority                     = number<br/>    protocol                     = string<br/>    source_address_prefixes      = list(string)<br/>    destination_address_prefixes = list(string)<br/>    source_port_ranges           = list(string)<br/>    destination_port_ranges      = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_network_security_groups"></a> [network\_security\_groups](#input\_network\_security\_groups) | Map of per-subnet NSG custom rule packs | <pre>map(object({<br/>    resource_name                 = string<br/>    resource_group_short_name     = string<br/>    virtual_network_short_name    = optional(string, "")<br/>    location                      = string<br/>    enable_explicit_inbound_deny  = optional(bool, true)<br/>    enable_explicit_outbound_deny = optional(bool, false)<br/>    rules = optional(list(<br/>      object({<br/>        name                         = string<br/>        access                       = string<br/>        direction                    = string<br/>        description                  = string<br/>        priority                     = number<br/>        protocol                     = string<br/>        source_address_prefixes      = list(string)<br/>        destination_address_prefixes = list(string)<br/>        source_port_ranges           = list(string)<br/>        destination_port_ranges      = list(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_network_topology_details"></a> [network\_topology\_details](#input\_network\_topology\_details) | Network Details for the environment | <pre>object({<br/>    network_type                  = optional(string, "")<br/>    create_gateways               = optional(bool, false)<br/>    create_vwan                   = optional(bool, false)<br/>    hub_peering_enabled           = optional(bool, true)<br/>    hub_id                        = optional(map(string), {})<br/>    virtual_wan_hubs              = optional(map(any), {})<br/>    bastion_subnet_address_spaces = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "bastion_subnet_address_spaces": [],<br/>  "create_gateways": false,<br/>  "create_vwan": false,<br/>  "hub_id": {},<br/>  "network_type": "",<br/>  "virtual_wan_hubs": {}<br/>}</pre> | no |
| <a name="input_org_abbreviation"></a> [org\_abbreviation](#input\_org\_abbreviation) | Organization or company abbreviation used in the ORG placeholder (e.g., 'contoso', 'acme', 'fabrikam'). Helps identify resources belonging to your organization. | `string` | n/a | yes |
| <a name="input_paas_allowed_ip_addresses"></a> [paas\_allowed\_ip\_addresses](#input\_paas\_allowed\_ip\_addresses) | n/a | `list(string)` | `[]` | no |
| <a name="input_recovery_services_vault"></a> [recovery\_services\_vault](#input\_recovery\_services\_vault) | Legacy placeholder for recovery services vault settings | `map(any)` | `{}` | no |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | n/a | <pre>map(<br/>    object({<br/>      resource_name           = string<br/>      resource_name_overwrite = optional(bool, false) // Should the resource name circumvent the naming standards, if so, the resource will be named as per resource_name.<br/>      location                = string<br/>      lock_enabled            = optional(bool, true) // Should this resource group have a lock applied to it?<br/>      lock_name               = optional(string, "")<br/>      tags                    = optional(map(string), {})<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_resource_groups_lock_override"></a> [resource\_groups\_lock\_override](#input\_resource\_groups\_lock\_override) | override configured resource group locks and do not create | `bool` | `false` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Map of Resource Objects to create for naming and reference | <pre>map(object({<br/>    resource_type           = string<br/>    resource_name           = string<br/>    resource_name_overwrite = optional(bool, false)<br/><br/>    resource_group_name           = optional(string, "")<br/>    resource_group_name_overwrite = optional(bool, false)<br/><br/>    location    = optional(string, null)<br/>    structure   = optional(string, null)<br/>    environment = optional(string, null)<br/>    archetype   = optional(string, null)<br/>    existing    = optional(bool, false)<br/>    case_option = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | n/a | <pre>map(<br/>    object({<br/>      resource_name                 = string<br/>      resource_group_short_name     = string<br/>      location                      = string<br/>      bgp_route_propagation_enabled = bool<br/>      routes = optional(list(<br/>        object({<br/>          name                   = string<br/>          address_prefix         = string<br/>          next_hop_type          = string<br/>          next_hop_in_ip_address = optional(string, "")<br/>      })), [])<br/>      tags = optional(map(string), {})<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_rsv_settings"></a> [rsv\_settings](#input\_rsv\_settings) | Settings for the Recovery Services Vault | <pre>object({<br/>    immutability                 = optional(string, "Disabled")<br/>    soft_delete_enabled          = optional(bool, true)<br/>    cross_region_restore_enabled = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "cross_region_restore_enabled": false,<br/>  "immutability": "Disabled",<br/>  "soft_delete_enabled": true<br/>}</pre> | no |
| <a name="input_storage_accounts"></a> [storage\_accounts](#input\_storage\_accounts) | Map of custom storage accounts to merge with templated storage accounts | <pre>map(object({<br/>    resource_name             = string<br/>    resource_group_short_name = string<br/>    location                  = string<br/>    account_replication_type  = string<br/>    access_tier               = string<br/>    account_tier              = string<br/>    shared_access_key_enabled = bool<br/>    network_rules = object({<br/>      creator_ip_rule = bool<br/>      default_action  = string<br/>      bypass          = list(string)<br/>    })<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_structure"></a> [structure](#input\_structure) | Naming structure pattern using placeholders: ORG, REGION, ENV, PURPOSE, ARCH, TYPE, NAME. Example: 'TYPE-ORG-REGION-ENV-ARCH-NAME' produces 'vm-contoso-uks-prod-web-app01'. | `string` | n/a | yes |
| <a name="input_subscription_details"></a> [subscription\_details](#input\_subscription\_details) | A Map of the Subscription details | <pre>object({<br/>    subscription_alias_enabled                            = optional(bool, false)<br/>    subscription_alias_name                               = optional(string, null)<br/>    subscription_billing_scope                            = optional(string, null)<br/>    subscription_display_name                             = string<br/>    subscription_id                                       = string<br/>    subscription_management_group_association_enabled     = optional(bool, false)<br/>    subscription_management_group_id                      = optional(string, null)<br/>    subscription_register_resource_providers_and_features = optional(map(set(string)), {})<br/>    subscription_register_resource_providers_enabled      = optional(bool, false)<br/>    subscription_tags                                     = optional(map(string), {})<br/>    subscription_update_existing                          = optional(bool, false)<br/>    subscription_workload                                 = optional(string, null)<br/>  })</pre> | n/a | yes |
| <a name="input_templated_locations"></a> [templated\_locations](#input\_templated\_locations) | List of locations to deploy templated resources to | `list(string)` | `[]` | no |
| <a name="input_virtual_networks"></a> [virtual\_networks](#input\_virtual\_networks) | Map of all Virtual Network | <pre>map(<br/>    object({<br/>      resource_name             = string<br/>      resource_group_short_name = string<br/>      location                  = string<br/>      address_space             = list(string)<br/>      dns_servers               = optional(list(string), [])<br/>      enable_nat_gw             = optional(bool, false)<br/>      hub_connection            = optional(bool, false)<br/>      subnets = list(<br/>        object({<br/>          route_table_short_name          = optional(string, "")<br/>          nsg_short_name                  = optional(string, "")<br/>          name                            = string<br/>          privateEndpointNetworkPolicies  = optional(string, "Enabled")<br/>          subnet_address_space            = string<br/>          service_endpoints               = optional(list(string), [])<br/>          nat_gateway_id                  = optional(string, "")<br/>          default_outbound_access_enabled = optional(bool, false)<br/>          delegation = optional(list(object({<br/>            name = string<br/>            service_delegation = object({<br/>              name    = string<br/>              actions = optional(list(string))<br/>            })<br/>          })), [])<br/>        })<br/>      )<br/>      peerings = optional(list(object({<br/>        resource_name                         = string<br/>        remote_vnet_resource_group_short_name = string<br/>        remote_vnet_environment               = string<br/>        remote_vnet_region                    = string<br/>        remote_vnet_short_name                = string<br/>        remote_vnet_subscription_id           = string<br/>      })), [])<br/>      tags = optional(map(string), {})<br/>    })<br/>  )</pre> | `{}` | no |
| <a name="input_workload_abbreviation"></a> [workload\_abbreviation](#input\_workload\_abbreviation) | Workload abbreviation used in the ARCH placeholder (e.g., 'web', 'db', 'api'). Helps identify the purpose of the resource. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_outputs"></a> [resource\_outputs](#output\_resource\_outputs) | n/a |
<!-- END_TF_DOCS -->