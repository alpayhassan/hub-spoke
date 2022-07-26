locals {
  hub-rgname   = "hub-vnet-rg"
  hub-location = "uksouth"
}

resource "azurerm_resource_group" "hub-rg" {
  name     = local.hub-rgname
  location = local.hub-location
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "hub-vnet"
  address_space       = ["10.4.0.0/16"]
  location            = local.hub-location
  resource_group_name = local.hub-rgname
}

resource "azurerm_subnet" "hub-subnet" {
  name                 = "mgmt-subnet-hub"
  resource_group_name  = local.hub-rgname
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.4.0.0/24"]
}

resource "azurerm_subnet" "hub-dmz-subnet" {
  name                 = "dmz-subnet-hub"
  resource_group_name  = local.hub-rgname
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.4.2.0/24"]
}

resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = local.hub-rgname
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.4.1.0/27"]
}

resource "azurerm_public_ip" "hub-pip" {
  name                = "hub-public-ip"
  location            = local.hub-location
  resource_group_name = local.hub-rgname
  allocation_method   = "Dynamic"
}


# Creating a Linux Virtual Machine in the Hub VNet
resource "azurerm_network_interface" "hub-nic" {
  name                 = "hub-nic"
  location             = local.hub-location
  resource_group_name  = local.hub-rgname
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "hub"
    subnet_id                     = azurerm_subnet.hub-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "hub-vm" {
  name                = "hub-vm"
  location            = local.hub-location
  resource_group_name = local.hub-rgname
  size                = var.vmsize
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.hub-nic.id
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


# Creating a VPN Gateway
resource "azurerm_public_ip" "hub-gateway-pip" {
  name                = "hub-GW-pip"
  location            = local.hub-location
  resource_group_name = local.hub-rgname

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vpn-gateway" {
  name                = "hub-GW"
  location            = local.hub-location
  resource_group_name = local.hub-rgname

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku        = var.gw_sku
  generation = "Generation1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.hub-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub-gateway-subnet.id
  }
  depends_on = [azurerm_public_ip.hub-gateway-pip]
}
