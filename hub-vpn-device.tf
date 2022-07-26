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
    private_ip_address            = "10.0.0.36"
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
