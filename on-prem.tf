locals {
  onprem-location = "uksouth"
  onprem-rgname   = "onprem-rg"
}

resource "azurerm_resource_group" "onprem-rg" {
  name     = local.onprem-rgname
  location = local.onprem-location
}

resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "onprem-subnet" {
  name                 = "default"
  resource_group_name  = local.onprem-rgname
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefixes     = ["192.168.1.128/25"]
}

resource "azurerm_subnet" "onprem-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = local.onprem-rgname
  virtual_network_name = azurerm_virtual_network.onprem-vnet.name
  address_prefixes     = ["192.168.255.224/27"]
}

resource "azurerm_public_ip" "onprem-pip" {
  name                = "onprem-pip"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname
  allocation_method   = "Dynamic"
}



# NSG & Rule
resource "azurerm_network_security_group" "onprem-nsg" {
  name                = "onprem-nsg"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_resource_group.onprem-rg]
}

resource "azurerm_subnet_network_security_group_association" "onprem-subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.onprem-subnet.id
  network_security_group_id = azurerm_network_security_group.onprem-nsg.id
}



# On-prem VM
resource "azurerm_network_interface" "onprem-nic" {
  name                 = "onprem-nic"
  location             = local.onprem-location
  resource_group_name  = local.onprem-rgname
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "onprem"
    subnet_id                     = azurerm_subnet.onprem-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onprem-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "onprem-vm" {
  name                = "onprem-vm"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname
  size                = var.vmsize
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.onprem-nic.id
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



# On-prem vpn gateway with gateway subnet and pip
resource "azurerm_public_ip" "onprem-gateway-pip" {
  name                = "onprem-GW-pip"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname

  allocation_method = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "onprem-vpn-gateway" {
  name                = "onprem-GW"
  location            = local.onprem-location
  resource_group_name = local.onprem-rgname

  type     = "Vpn"
  vpn_type = "RouteBased"

  sku        = var.gw_sku
  generation = "Generation1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onprem-gateway-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.onprem-gateway-subnet.id
  }
  depends_on = [azurerm_public_ip.onprem-gateway-pip]
}
