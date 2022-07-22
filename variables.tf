variable "vmsize" {
  default = "Standard_F2"
}

variable "username" {
  default     = "demousr"
  description = "Username for the VMs"
}

variable "gw_sku" {
  default     = "VpnGw1"
  description = "SKU for virtual network gateway"
}
