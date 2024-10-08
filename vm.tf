resource "random_password" "vm" {
  length           = 16
  special          = true
  override_special = "_%@"
}

moved {
  from = azurerm_role_assignment.Reader
  to   = azurerm_role_assignment.Contributor
}

resource "azurerm_role_assignment" "Contributor" {
  scope                = azurerm_linux_virtual_machine.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

resource "azurerm_application_insights" "example" {
  name                = "chaos-appinsights"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "other"
  retention_in_days   = 30
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "chaos-vm"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = "Standard_B4ms"
  admin_username                  = "adminuser"
  admin_password                  = random_password.vm.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  # This identity is required to assign the VM as an azurerm_chaos_studio_target
  identity {
    type = "SystemAssigned"
    # identity_ids = [
    #   azurerm_user_assigned_identity.this.id,
    # ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
    # publisher = "Canonical"
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts"
    # version   = "latest"
  }
}
