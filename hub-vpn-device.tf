locals {
  prefix-device   = "hub-vpn-device"
  device-location = "uksouth"
  device-rgname   = "hub-vpn-device-rg"
}

resource "azurerm_resource_group" "device-rg" {
  name     = local.device-rgname
  location = local.device-location
}

# Creating an Ubuntu image VM acting as a VPN Device
resource "azurerm_network_interface" "device-nic" {
  name                 = "${local.prefix-device}-nic"
  location             = local.device-location
  resource_group_name  = local.device-rgname
  enable_ip_forwarding = true

  ip_configuration {
    name                          = local.prefix-device
    subnet_id                     = azurerm_subnet.hub-dmz-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.4.2.12"
  }
  depends_on = [azurerm_subnet.hub-dmz-subnet]
}

resource "azurerm_linux_virtual_machine" "vpn-device" {
  name                = "${local.prefix-device}-vm"
  location            = local.device-location
  resource_group_name = local.device-rgname
  size                = var.vmsize
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.device-nic.id
  ]

  admin_ssh_key {
    username   = var.username
    public_key = file("./linux-vmkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}



# VM extension to enable routing in the "VPN Device"
# Referencing the MSPNP github page raw script
resource "azurerm_virtual_machine_extension" "enable-routes" {
  name                 = "enable-iptables-routes"
  virtual_machine_id   = azurerm_linux_virtual_machine.vpn-device.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "fileUris": [
      "https://raw.githubusercontent.com/mspnp/reference-architectures/master/scripts/linux/enable-ip-forwarding.sh"
      ],
      "commandToExecute": "bash enable-ip-forwarding.sh"
  }
SETTINGS

}



# Creating route tables for the ips through the VPN Device to a destination
resource "azurerm_route_table" "hub-gateway-rt" {
  name                          = "hub-gateway-rt"
  location                      = local.device-location
  resource_group_name           = local.device-rgname
  disable_bgp_route_propagation = false

  route {
    name                   = "destination-hub"
    address_prefix         = "10.4.0.0/16"
    next_hop_type          = "VnetLocal"
  }

  route {
    name           = "destination-spoke1"
    address_prefix = "10.5.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.4.0.36"
  }

  route {
    name                   = "destination-spoke2"
    address_prefix         = "10.6.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.4.0.36"
  }
}

resource "azurerm_subnet_route_table_association" "hub-gateway-rt-hub-gateway-subnet" {
  subnet_id      = azurerm_subnet.hub-gateway-subnet.id
  route_table_id = azurerm_route_table.hub-gateway-rt.id
  depends_on     = [azurerm_subnet.hub-gateway-subnet]
}




# Spoke 1 route table
resource "azurerm_route_table" "spoke1-rt" {
  name                          = "spoke1-rt"
  location                      = local.device-location
  resource_group_name           = local.device-rgname
  disable_bgp_route_propagation = false

  route {
    name                   = "destination-spoke2"
    address_prefix         = "10.6.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.4.0.36"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "spoke1-rt-spoke1-subnet" {
  subnet_id      = azurerm_subnet.spoke1-mgmt-subnet.id
  route_table_id = azurerm_route_table.spoke1-rt.id
  depends_on     = [azurerm_subnet.spoke1-mgmt-subnet]
}



# Spoke 2 route table
resource "azurerm_route_table" "spoke2-rt" {
  name                          = "spoke2-rt"
  location                      = local.device-location
  resource_group_name           = local.device-rgname
  disable_bgp_route_propagation = false

  route {
    name                   = "destination-spoke1"
    address_prefix         = "10.5.0.0/16"
    next_hop_in_ip_address = "10.4.0.36"
    next_hop_type          = "VirtualAppliance"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "spoke2-rt-spoke2-subnet" {
  subnet_id      = azurerm_subnet.spoke2-mgmt-subnet.id
  route_table_id = azurerm_route_table.spoke2-rt.id
  depends_on     = [azurerm_subnet.spoke2-mgmt-subnet]
}
