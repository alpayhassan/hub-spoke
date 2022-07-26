resource "azurerm_route_table" "hub-gateway-rt" {
  name                          = "hub-gw-rt"
  location                      = azurerm_resource_group.device-rg.location
  resource_group_name           = azurerm_resource_group.device-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "to-hub"
    address_prefix = "10.0.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  route {
    name                   = "to-spoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  route {
    name                   = "to-spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }
}

resource "azurerm_subnet_route_table_association" "hub-gateway-subnet-rt" {
  subnet_id      = azurerm_subnet.hub-gateway-subnet.id
  route_table_id = azurerm_route_table.hub-gateway-rt.id

  depends_on = [azurerm_subnet.hub-gateway-subnet]
}


# Spoke 1 route table
resource "azurerm_route_table" "spoke1-rt" {
  name                          = "spoke1-rt"
  location                      = azurerm_resource_group.device-rg.location
  resource_group_name           = azurerm_resource_group.device-rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "to-spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "spoke1-rt-vnet-mgmt" {
  subnet_id      = azurerm_subnet.spoke1-mgmt-subnet.id
  route_table_id = azurerm_route_table.spoke1-rt.id

  depends_on = [azurerm_subnet.spoke1-mgmt-subnet]
}

resource "azurerm_subnet_route_table_association" "spoke1-rt-vnet-workload" {
  subnet_id      = azurerm_subnet.spoke1-workload-subnet.id
  route_table_id = azurerm_route_table.spoke1-rt.id

  depends_on = [azurerm_subnet.spoke1-workload-subnet]
}

# Spoke 2 route table
resource "azurerm_route_table" "spoke2-rt" {
  name                          = "spoke2-rt"
  location                      = azurerm_resource_group.device-rg.location
  resource_group_name           = azurerm_resource_group.device-rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "to-spoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.36"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "spoke2-rt-vnet-mgmt" {
  subnet_id      = azurerm_subnet.spoke2-mgmt-subnet.id
  route_table_id = azurerm_route_table.spoke2-rt.id

  depends_on = [azurerm_subnet.spoke2-mgmt-subnet]
}

resource "azurerm_subnet_route_table_association" "spoke2-rt-vnet-workload" {
  subnet_id      = azurerm_subnet.spoke2-workload-subnet.id
  route_table_id = azurerm_route_table.spoke2-rt.id

  depends_on = [azurerm_subnet.spoke2-workload-subnet]
}
