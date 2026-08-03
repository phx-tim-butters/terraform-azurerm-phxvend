module "network_security_group" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  enable_telemetry = false

  name = var.network_security_group_name

  location            = var.default_location
  resource_group_name = var.resource_group_name

  security_rules = local.security_rules

  tags = var.tags
}
