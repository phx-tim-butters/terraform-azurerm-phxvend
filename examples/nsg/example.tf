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

  default_location            = "uksouth"
  resource_group_name         = "vend_nsg-example"
  network_security_group_name = "vend_nsg-example"

  tags = {}

  network_security_group_properties = {
    enable_explicit_inbound_deny  = true
    enable_explicit_outbound_deny = false
    subnet_address_spaces         = ["10.0.0.0/24"]
    bastion_subnet_address_spaces = []
    subnet_name                   = "subnet1"
  }

  network_security_group_custom_rules = {
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
}

resource "azurerm_resource_group" "example" {
  name     = local.resource_group_name
  location = local.default_location

  tags = local.tags
}


module "network_security_group" {
  source = "../../modules/network_security_group"

  default_location                    = local.default_location
  resource_group_name                 = azurerm_resource_group.example.name
  network_security_group_name         = local.network_security_group_name
  network_security_group_custom_rules = local.network_security_group_custom_rules
  network_security_group_properties   = local.network_security_group_properties

  module_avm_res_network_networksecuritygroup_version = "0.5.1"
}
