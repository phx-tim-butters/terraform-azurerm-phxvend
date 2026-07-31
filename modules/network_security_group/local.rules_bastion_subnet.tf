locals {
  bastion_subnet_rules = {
    Allow-HTTPs-Inbound = {
      name        = ""
      access      = "allow"
      direction   = "Inbound"
      description = ""
      priority    = "151"
      protocol    = "tcp"
      source_address_prefixes = [
        "TAG-Internet"
      ],
      destination_address_prefixes = ["*"]
      source_port_ranges           = ["*"]
      destination_port_ranges = [
        "443"
      ]
    }
    Allow-BastionControlPlane-Inbound = {
      name        = ""
      access      = "allow",
      direction   = "Inbound",
      description = "",
      priority    = "152",
      protocol    = "tcp",
      source_address_prefixes = [
        "TAG-GatewayManager"
      ],
      destination_address_prefixes = ["*"]
      source_port_ranges           = ["*"]
      destination_port_ranges = [
        "443"
      ]
    }
    Allow-BastionDataPlane-Inbound = {
      name        = ""
      access      = "allow",
      direction   = "Inbound",
      description = "",
      priority    = "153",
      protocol    = "*",
      source_address_prefixes = [
        "TAG-VirtualNetwork"
      ],
      destination_address_prefixes = [
        "TAG-VirtualNetwork"
      ],
      source_port_ranges = ["*"]
      destination_port_ranges = [
        "8080",
        "5701"
      ]
    }
    AllowAzureLoadBalancerInbound = {
      name        = ""
      access      = "allow",
      direction   = "Inbound",
      description = "",
      priority    = "154",
      protocol    = "tcp",
      source_address_prefixes = [
        "TAG-AzureLoadBalancer"
      ],
      destination_address_prefixes = ["*"]
      source_port_ranges           = ["*"]
      destination_port_ranges = [
        "443"
      ]
    }
    Deny-All-Inbound = {
      name                         = ""
      access                       = "deny",
      direction                    = "Inbound",
      description                  = "",
      priority                     = "4096",
      protocol                     = "*",
      source_address_prefixes      = ["*"]
      destination_address_prefixes = ["*"]
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
    Allow-BastionSshRdp-Outbound = {
      name                    = ""
      access                  = "allow",
      direction               = "Outbound",
      description             = "",
      priority                = "151",
      protocol                = "tcp",
      source_address_prefixes = ["*"]
      destination_address_prefixes = [
        "TAG-VirtualNetwork"
      ],
      source_port_ranges = ["*"]
      destination_port_ranges = [
        "22",
        "3389"
      ]
    }
    Allow-BastionAzureCloud-Outbound = {
      name                    = ""
      access                  = "allow",
      direction               = "Outbound",
      description             = "",
      priority                = "152",
      protocol                = "tcp",
      source_address_prefixes = ["*"]
      destination_address_prefixes = [
        "TAG-AzureCloud"
      ],
      source_port_ranges = ["*"]
      destination_port_ranges = [
        "443"
      ]
    }
    Allow-BastionDataPlane-Outbound = {
      name        = ""
      access      = "allow",
      direction   = "Outbound",
      description = "",
      priority    = "153",
      protocol    = "tcp",
      source_address_prefixes = [
        "TAG-VirtualNetwork"
      ],
      destination_address_prefixes = [
        "TAG-VirtualNetwork"
      ],
      source_port_ranges = ["*"]
      destination_port_ranges = [
        "8080",
        "5701"
      ]
    }
    Allow-BastionSessionInfo-Outbound = {
      name                    = ""
      access                  = "allow",
      direction               = "Outbound",
      description             = "",
      priority                = "154",
      protocol                = "tcp",
      source_address_prefixes = ["*"]
      destination_address_prefixes = [
        "TAG-Internet"
      ],
      source_port_ranges = ["*"]
      destination_port_ranges = [
        "80"
      ]
    }
    Deny-All-Outbound = {
      name                         = ""
      access                       = "deny",
      direction                    = "Outbound",
      description                  = "",
      priority                     = "4096",
      protocol                     = "*",
      source_address_prefixes      = ["*"]
      destination_address_prefixes = ["*"]
      source_port_ranges           = ["*"]
      destination_port_ranges      = ["*"]
    }
  }
}
