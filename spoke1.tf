locals {
  spoke1-rgname = "Development Environment"
  spoke1-location = "uksouth"
}

resource "azurerm_resource_group" "spoke1-rg" {
  name     = local.spoke1-rgname
  location = local.spoke1-location
}

resource "azurerm_virtual_network" "spoke1-vnet" {
  name                = "development-network"
  address_space       = ["10.5.0.0/16"]
  location            = local.spoke1-location
  resource_group_name = local.spoke1-rgname
}

resource "azurerm_subnet" "spoke1-subnet" {
  name                 = "development-default-subnet"
  resource_group_name  = local.spoke1-rgname
  virtual_network_name = azurerm_virtual_network.spoke1-vnet.name
  address_prefixes     = ["10.5.0.0/24"]
}


# Creating development environment VMs
resource "azurerm_network_interface" "spoke1-nic" {
  name                = "spoke1-nic"
  location            = local.spoke1-location
  resource_group_name = local.spoke1-rgname
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "spoke1"
    subnet_id                     = azurerm_subnet.spoke1-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke1vm1" {
  name                = "dev-vm-1"
  location            = local.spoke1-location
  resource_group_name = local.spoke1-rgname
  size                = var.vmsize
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.spoke1-nic.id
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


# VNet peering between hub and spoke
resource "azurerm_virtual_network_peering" "hub-to-spoke1-peering" {
  name                      = "peeringhubtospoke1"
  resource_group_name       = local.spoke1-rgname
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1-vnet.id
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub-peering" {
  name                      = "peeringspoke1tohub"
  resource_group_name       = local.spoke1-rgname
  virtual_network_name      = azurerm_virtual_network.spoke1-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
}
