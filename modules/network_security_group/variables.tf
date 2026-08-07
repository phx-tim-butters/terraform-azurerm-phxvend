variable "default_location" {
  type        = string
  description = "The location of the resource object"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "network_security_group_name" {
  description = "Name of the Network Security Group"
  type        = string
}

variable "network_security_group_custom_rules" {
  description = "A map of any custom network security group rules to include in the NSG"
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

variable "network_security_group_custom_default_rules" {
  description = "A map of any custom default network security group rules to include in the NSG"
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

variable "network_security_group_properties" {
  description = "Behavior flags and context values used to construct baseline NSG rules (explicit deny toggles, subnet ranges, Bastion ranges, and subnet name context)."
  type = object({
    enable_explicit_inbound_deny  = optional(bool, true)
    enable_explicit_outbound_deny = optional(bool, true)
    subnet_address_spaces         = optional(list(string), [])
    bastion_subnet_address_spaces = optional(list(string), [])
    subnet_name                   = optional(string, null)
  })
}

variable "tags" {
  description = "A map of tags to apply to the resource object"
  type        = map(string)
  default     = {}
}
