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
