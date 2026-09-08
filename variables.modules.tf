variable "module_phx_naming_version" {
  description = "The version of the naming module to use."
  type        = string
  const       = true
  default     = "0.1.8"
}

variable "module_avm_res_storage_storageaccount_version" {
  description = "The version of the storage account module to use."
  type        = string
  const       = true
  default     = "0.10.0"
}

variable "module_avm_res_network_networksecuritygroup_version" {
  description = "The version of the network security group module to use."
  type        = string
  const       = true
  default     = "0.5.1"
}

variable "module_avm_res_network_virtualnetwork_version" {
  description = "The version of the virtual network module to use."
  type        = string
  const       = true
  default     = "0.22.2"
}

variable "module_avm_ptn_alz_sub_vending_version" {
  description = "The version of the subscription vending module to use."
  type        = string
  const       = true
  default     = "0.3.1"
}
