variable "default_location" {
  type        = string
  description = "The location of the resource object"
}

variable "bastion_subnet_address_spaces" {
  description = "Details of Bastion subnets, used for default NSG rules"
  type        = list(string)
  default     = []
}

variable "subnet" {
  description = "Subnet to create as object"
  type = object({
    resource_name    = string
    address_prefixes = list(string)
    service_endpoints = optional(list(object({
      service   = string
      locations = optional(list(string), [])
    })), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    })), [])
    private_endpoint_network_policies_enabled = optional(bool, false)
    route_table_id                            = optional(string)
  })
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
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

variable "network_security_group_name_prefix" {
  description = "Name of the network security group to create"
  type        = string
}

variable "network_security_group_creation_enabled" {
  description = "Boolean to determine if the network security group should be created"
  type        = bool
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the resource object"
  default     = {}
}
