locals {
  IPSec-key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

# Gateway connection between on-prem and hub VNETs
resource "azurerm_virtual_network_gateway_connection" "onprem-to-hub" {
  name                = "onprem-to-hub"
  location            = azurerm_resource_group.onprem-rg.location
  resource_group_name = azurerm_resource_group.onprem-rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.onprem-vpn-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.hub-vpn-gateway.id

  shared_key = local.IPSec-key
}

resource "azurerm_virtual_network_gateway_connection" "hub-to-onprem" {
  name                = "hub-to-onprem"
  location            = azurerm_resource_group.hub-rg.location
  resource_group_name = azurerm_resource_group.hub-rg.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.hub-vpn-gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.onprem-vpn-gateway.id

  shared_key = local.IPSec-key
}
