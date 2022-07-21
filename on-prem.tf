locals {
  onprem-location = "uksouth"
  onprem-rgname   = "onprem-vnet-rg"

}

resource "azurerm_resource_group" "on-prem-rg" {
  name     = local.onprem-rgname
  location = local.onprem-location
}

resource "azurerm_virtual_network" "on-prem-vnet" {
  name                = "onprem-vnet"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname
  address_space       = ["10.3.0.0/16"]

  subnet {
    name           = "default-onprem"
    address_prefix = "10.3.0.0/24"
  }
}

# NSGs


# Creating a VM to act as a VPN device to provivde external connectivity to on_prem


# Creating an on-prem vpn gateway with gateway subnet and pip
resource "azurerm_subnet" "onprem-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.rgname
  virtual_network_name = var.vnname
  address_prefixes     = ["10.3.1.0/27"]
}

resource "azurerm_public_ip" "onprem-public-ip" {
  name                = "hub_gateway_ip"
  location            = var.location
  resource_group_name = var.rgname

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
  name                = "onprem-gateway"
  location            = var.location
  resource_group_name = var.rgname

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku        = var.gw_sku
  generation = "Generation1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gw_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gw_subnet.id
  }
  depends_on = [azurerm_public_ip.gw_ip]
}
