locals {

  custom_rules = { for rule in var.network_security_group_custom_rules : rule.name => {
    name                         = rule.name
    access                       = rule.access
    direction                    = rule.direction
    description                  = rule.description
    priority                     = rule.priority
    protocol                     = rule.protocol
    source_address_prefixes      = flatten([for address in rule.source_address_prefixes : [for a in var.network_security_group_properties.subnet_address_spaces : replace(address, "*SUBNETADDRESSSPACE*", a)]])
    destination_address_prefixes = flatten([for address in rule.destination_address_prefixes : [for a in var.network_security_group_properties.subnet_address_spaces : replace(address, "*SUBNETADDRESSSPACE*", a)]])
    source_port_ranges           = rule.source_port_ranges
    destination_port_ranges      = rule.destination_port_ranges
    }
  }
}
