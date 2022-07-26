# VNet peering between hub and spoke 1
resource "azurerm_virtual_network_peering" "hub-to-spoke1-peering" {
  name                      = "peering-hubtospoke1"
  resource_group_name       = azurerm_resource_group.hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1-vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false

  depends_on                = [azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vpn-gateway, azurerm_virtual_network.spoke1-vnet]
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub-peering" {
  name                      = "peering-spoke1tohub"
  resource_group_name       = local.spoke1-rgname
  virtual_network_name      = azurerm_virtual_network.spoke1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true

  depends_on                = [azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vpn-gateway, azurerm_virtual_network.spoke1-vnet]
}


# VNet peering between hub and spoke 2
resource "azurerm_virtual_network_peering" "hub-to-spoke2-peering" {
  name                      = "peering-hubtospoke2"
  resource_group_name       = azurerm_resource_group.hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2-vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  use_remote_gateways       = false

  depends_on                = [azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vpn-gateway, azurerm_virtual_network.spoke2-vnet]
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub-peering" {
  name                      = "peering-spoke2tohub"
  resource_group_name       = local.spoke2-rgname
  virtual_network_name      = azurerm_virtual_network.spoke2-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = true

  depends_on                = [azurerm_virtual_network.hub-vnet, azurerm_virtual_network_gateway.hub-vpn-gateway, azurerm_virtual_network.spoke2-vnet]
}
