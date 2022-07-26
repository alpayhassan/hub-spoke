locals {
  spoke2-rgname   = "testing-environment-RG"
  spoke2-location = "uksouth"
}

resource "azurerm_resource_group" "example" {
  name     = local.spoke2-rgname
  location = local.spoke2-location
}

resource "azurerm_virtual_network" "spoke2-vnet" {
  name                = "testing-network"
  address_space       = ["10.2.0.0/16"]
  location            = local.spoke2-location
  resource_group_name = local.spoke2-rgname
}

resource "azurerm_subnet" "spoke2-mgmt-subnet" {
  name                 = "testing-default-subnet"
  resource_group_name  = local.spoke2-rgname
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["10.2.0.64/27"]
}

resource "azurerm_subnet" "spoke2-workload-subnet" {
  name                 = "testing-workload-subnet"
  resource_group_name  = local.spoke2-rgname
  virtual_network_name = azurerm_virtual_network.spoke2-vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}


# Creating testing environment VMs
resource "azurerm_network_interface" "spoke2-nic" {
  name                 = "spoke2-nic"
  location             = local.spoke2-location
  resource_group_name  = local.spoke2-rgname
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "spoke2"
    subnet_id                     = azurerm_subnet.spoke2-mgmt-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "spoke2vm1" {
  name                = "testing-vm-1"
  location            = local.spoke2-location
  resource_group_name = local.spoke2-rgname
  size                = var.vmsize
  admin_username      = var.username
  network_interface_ids = [
    azurerm_network_interface.spoke2-nic.id
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
