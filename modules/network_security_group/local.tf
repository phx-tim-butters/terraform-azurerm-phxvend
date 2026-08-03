locals {
  merged_rules = merge(
    local.fixed_default_rules_inbound_intrasubnet,
    local.fixed_default_rules_inbound_deny,
    local.fixed_default_rules,
    local.subnet_bastion_rules,
    local.custom_rules,
    strcontains(var.network_security_group_properties.subnet_name, "AzureBastionSubnet") ? local.bastion_subnet_rules : {}
  )
}

locals {
  security_rules = { for k, rule in local.merged_rules : k => {
    name        = k
    description = try(rule.description, "")
    access      = title(rule.access)
    priority    = rule.priority
    direction   = title(rule.direction)
    protocol    = title(rule.protocol)

    destination_port_ranges      = contains(rule.destination_port_ranges, "*") ? null : rule.destination_port_ranges
    destination_port_range       = contains(rule.destination_port_ranges, "*") ? "*" : null
    destination_address_prefixes = contains(rule.destination_address_prefixes, "*") || length(regexall("T.*G-", rule.destination_address_prefixes[0])) > 0 ? null : rule.destination_address_prefixes
    destination_address_prefix   = contains(rule.destination_address_prefixes, "*") || length(regexall("T.*G-", rule.destination_address_prefixes[0])) > 0 ? replace(rule.destination_address_prefixes[0], "TAG-", "") : null
    source_address_prefixes      = contains(rule.source_address_prefixes, "*") || length(regexall("T.*G-", rule.source_address_prefixes[0])) > 0 ? null : rule.source_address_prefixes
    source_address_prefix        = contains(rule.source_address_prefixes, "*") || length(regexall("T.*G-", rule.source_address_prefixes[0])) > 0 ? replace(rule.source_address_prefixes[0], "TAG-", "") : null
    source_port_ranges           = contains(rule.source_port_ranges, "*") ? null : rule.source_port_ranges
    source_port_range            = contains(rule.source_port_ranges, "*") ? "*" : null
  } }
}
