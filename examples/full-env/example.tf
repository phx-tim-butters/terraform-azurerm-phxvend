terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

variable "subscription_id" {
  type        = string
  description = "The subscription ID to use."
}

variable "tenant_id" {
  type        = string
  description = "The tenant ID to use."
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}


locals {
  ############### PRIMARY INFORMATION ###############

  default_location      = "uksouth"   // set to null if you want to enforce locations to come from config 
  templated_locations   = ["uksouth"] // set to null if you want to enforce locations to come from config
  org_abbreviation      = "example"
  deploy_abbreviation   = "" // is this being deployed to a seperate environment (like dev) where all the resources need appending?
  structure             = "TYPE-ORG-REGION-WORK-NAME"
  workload_abbreviation = "example-vend"

  #### Subscriptions and Tenant Detail ####
  tenant_id = var.tenant_id

  subscription_details = {
    subscription_id              = var.subscription_id
    subscription_alias_enabled   = false
    subscription_display_name    = "sub-example_vend"
    subscription_update_existing = false
  }

  #### Core Platform Resources Detail ####

  # Bastion Details
  bastion_address_spaces = [
    "10.100.3.0/26"
  ]

  resource_groups_lock_override = true

  network_topology_details = {
    network_type        = "Vnet-gw"
    gw_enabled          = false
    hub_peering_enabled = false
    hub_id              = {}
  }

  default_resource_group_tags = {
    Service = "Application-Vend-Test"
  }

  network_security_group_custom_default_rules = {
    Allow-IntraSubnet-Inbound = {
      name                         = "Allow-IntraSubnet-Inbound"
      access                       = "allow"
      direction                    = "Inbound"
      description                  = "Allow IntraSubnet Communication"
      priority                     = 100
      protocol                     = "*"
      source_address_prefixes      = ["*SUBNETADDRESSSPACE*"]
      destination_address_prefixes = ["*SUBNETADDRESSSPACE*"]
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
    Allow-OnPrem-Inbound = {
      name        = "Allow-OnPrem-Inbound"
      access      = "allow"
      direction   = "Inbound"
      description = "Allow On Prem address space to Subnet"
      priority    = 500
      protocol    = "*"
      source_address_prefixes = [
        "10.0.0.0/8",
        "192.168.0.0/16",
        "172.16.0.0/12"
      ]
      destination_address_prefixes = ["*SUBNETADDRESSSPACE*"]
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
  }

  resource_groups = {
    example_test = {
      resource_name             = "example_test"
      resource_group_short_name = "example"
      location                  = "uksouth"
    }
  }

  virtual_networks = {
    spoke = {
      resource_name             = "spoke"
      resource_group_short_name = "network"
      location                  = "uksouth"
      hub_connection            = false
      address_space             = ["10.64.16.0/20"]
      dns_servers = [
        "10.7.4.4",
        "10.7.4.5"
      ]
      subnets = [
        {
          route_table_short_name         = ""
          nsg_short_name                 = "snet-example"
          name                           = "snet-example"
          privateEndpointNetworkPolicies = "Enabled"
          subnet_address_space           = "10.64.16.0/23"
          nat_gateway_id                 = ""
        }
      ]
      peerings = []
      tags     = {}
    }
  }

  network_security_groups = {
    "uksouth-network-snet-example" = {
      resource_name              = "example_additional"
      resource_group_short_name  = "network"
      virtual_network_short_name = "spoke"
      location                   = "uksouth"
      rules = [
        {
          name        = "Allow-Example-Test"
          access      = "allow"
          direction   = "Inbound"
          description = "Allow On Prem address space to Subnet"
          priority    = 500
          protocol    = "*"
          source_address_prefixes = [
            "10.0.0.0/8"
          ]
          destination_address_prefixes = [
            "192.168.10.2"
          ]
          source_port_ranges      = ["*"]
          destination_port_ranges = ["*"]
        }
      ]
      tags = {}
    }
  }

  route_tables = {
    DefaultToFirewall = {
      resource_name                 = "example_default_to_firewall"
      resource_group_short_name     = "network"
      location                      = "uksouth"
      archetype                     = "prod"
      bgp_route_propagation_enabled = false
      routes = [
        {
          name                   = "ToFirewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.200.0.68"
        }
      ]
    }
  }
}

module "vend" {
  source = "../.."

  subscription_details = local.subscription_details
  default_location     = local.default_location
  templated_locations  = local.templated_locations

  network_topology_details = local.network_topology_details

  org_abbreviation      = local.org_abbreviation
  deploy_abbreviation   = local.deploy_abbreviation
  structure             = local.structure
  workload_abbreviation = local.workload_abbreviation

  resource_groups               = local.resource_groups
  resource_groups_lock_override = local.resource_groups_lock_override
  default_resource_group_tags   = local.default_resource_group_tags

  virtual_networks                            = local.virtual_networks
  bastion_address_spaces                      = local.bastion_address_spaces
  network_security_group_custom_default_rules = local.network_security_group_custom_default_rules

  network_security_groups = local.network_security_groups
  route_tables            = local.route_tables
}
