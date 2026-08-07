variable "module_phx_naming_version" {
  description = "The version of the naming module to use."
  type        = string
  default     = "0.1.7"
}

variable "module_avm_res_storage_storageaccount_version" {
  description = "The version of the storage account module to use."
  type        = string
  default     = "0.6.3"
}

variable "module_avm_res_network_networksecuritygroup_version" {
  description = "The version of the network security group module to use."
  type        = string
  default     = "0.5.1"
}

variable "module_avm_res_network_virtualnetwork_version" {
  description = "The version of the virtual network module to use."
  type        = string
  default     = "0.5.1"
}
