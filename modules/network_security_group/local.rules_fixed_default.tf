locals {

  fixed_default_rules_inbound_intrasubnet = length(var.network_security_group_properties.subnet_address_spaces) >= 1 ? {
    Allow-IntraSubnet-Inbound = {
      name                         = "Allow-IntraSubnet-Inbound"
      access                       = "allow"
      direction                    = "Inbound"
      description                  = ""
      priority                     = "100"
      protocol                     = "*"
      source_address_prefixes      = var.network_security_group_properties.subnet_address_spaces
      destination_address_prefixes = var.network_security_group_properties.subnet_address_spaces
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
  } : {}

  fixed_default_rules_inbound_deny = var.network_security_group_properties.enable_explicit_inbound_deny ? {
    Deny-All-Inbound = {
      name                         = "Deny-All-Inbound"
      access                       = "deny"
      direction                    = "Inbound"
      description                  = ""
      priority                     = "4096"
      protocol                     = "*"
      source_address_prefixes      = ["*"]
      destination_address_prefixes = try(var.network_security_group_properties.subnet_address_spaces, ["*"])
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
  } : {}

  fixed_default_rules = {
    Allow-AzureLoadBalancer-Inbound = {
      name        = "Allow-AzureLoadBalancer-Inbound"
      access      = "allow"
      direction   = "Inbound"
      description = ""
      priority    = "4095"
      protocol    = "*"
      source_address_prefixes = [
        "TAG-AzureLoadBalancer"
      ]
      destination_address_prefixes = try(var.network_security_group_properties.subnet_address_spaces, ["*"])
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
  }

  // If there are Bastion subnets in the incoming module call, then add them to a Bastion inbound rule.
  subnet_bastion_rules = length(var.network_security_group_properties.bastion_subnet_address_spaces) >= 1 ? {
    Allow-AzureBastion-Inbound = {
      name                         = ""
      access                       = "allow"
      direction                    = "Inbound"
      description                  = ""
      priority                     = "4094"
      protocol                     = "*"
      source_address_prefixes      = var.network_security_group_properties.bastion_subnet_address_spaces
      destination_address_prefixes = var.network_security_group_properties.subnet_address_spaces
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["22", "3389"]
    }
  } : {}
}
