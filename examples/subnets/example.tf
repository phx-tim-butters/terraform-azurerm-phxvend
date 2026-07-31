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

  default_location              = "uksouth"
  resource_group_name           = "vend_subnet-example"
  virtual_network_name          = "vend_subnet-example"
  network_security_group_prefix = "vend_subnet-example"
  virtual_network_address_space = "10.64.0.0/16"

  tags = {}

  subnets = {
    subnet1 = {
      resource_name    = "snet-test1"
      address_prefixes = ["10.64.20.0/27", "10.64.20.192/27"]
    }
    subnet2 = {
      resource_name    = "snet-test2"
      address_prefixes = ["10.64.20.32/27"]
    }
    subnet3 = {
      resource_name    = "snet-test3"
      address_prefixes = ["10.64.20.64/27"]
    }
    subnet4 = {
      resource_name    = "snet-test4"
      address_prefixes = ["10.64.20.96/27"]
    }
    subnet5 = {
      resource_name    = "snet-test5"
      address_prefixes = ["10.64.20.128/27"]
    }
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

resource "azurerm_virtual_network" "example" {
  name                = local.virtual_network_name
  location            = local.default_location
  resource_group_name = azurerm_resource_group.example.name

  address_space = [local.virtual_network_address_space]

  tags = local.tags
}


module "subnet" {
  source   = "../../modules/subnet"
  for_each = local.subnets

  default_location                    = local.default_location
  virtual_network_id                  = azurerm_virtual_network.example.id
  subnet                              = each.value
  network_security_group_name_prefix  = local.network_security_group_prefix
  network_security_group_custom_rules = local.network_security_group_custom_rules
}
