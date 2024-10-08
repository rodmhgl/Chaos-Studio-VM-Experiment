resource "azurerm_user_assigned_identity" "this" {
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  name                = "uai-chaos"
}

resource "azapi_resource" "chaos_target_agent" {
  body = jsonencode({
    properties = {
      # agentProfileId    = "0553fc04-255d-4965-b30b-9b3079e2f891"
      # agentTenantId     = "CHAOSSTUDIO"
      # allowPublicAccess = true
      identities = [{
        clientId = "73a76585-432f-4407-a96f-0ab623f3e020"
        tenantId = "d3164c0e-9807-4863-a439-becceb8459d9"
        type     = "AzureManagedIdentity"
      }]
      # privateAccessId = null
    }
  })
  ignore_casing             = false
  ignore_missing_property   = true
  location                  = "eastus"
  locks                     = null
  name                      = "Microsoft-Agent"
  parent_id                 = azurerm_linux_virtual_machine.this.id #"/subscriptions/02892755-eecf-4df8-bc08-a55279be6b35/resourceGroups/chaos-rg/providers/Microsoft.Compute/virtualMachines/chaos-vm"
  response_export_values    = null
  schema_validation_enabled = true
  tags                      = {}
  type                      = "Microsoft.Chaos/targets@2023-04-15-preview"
}

resource "azapi_resource" "chaos_target_vm" {
  body = jsonencode({
    properties = {}
  })
  ignore_casing             = false
  ignore_missing_property   = true
  location                  = "eastus"
  locks                     = null
  name                      = "Microsoft-VirtualMachine"
  parent_id                 = azurerm_linux_virtual_machine.this.id #"/subscriptions/02892755-eecf-4df8-bc08-a55279be6b35/resourceGroups/chaos-rg/providers/Microsoft.Compute/virtualMachines/chaos-vm"
  response_export_values    = null
  schema_validation_enabled = true
  tags                      = {}
  type                      = "Microsoft.Chaos/targets@2023-04-15-preview"
}

resource "azapi_resource" "vm_shutdown_capability" {
  body                      = jsonencode({})
  ignore_casing             = false
  ignore_missing_property   = true
  location                  = null
  locks                     = null
  name                      = "Shutdown-1.0"
  parent_id                 = azapi_resource.chaos_target_vm.id #"/subscriptions/02892755-eecf-4df8-bc08-a55279be6b35/resourceGroups/chaos-rg/providers/Microsoft.Compute/virtualMachines/chaos-vm/providers/Microsoft.Chaos/targets/Microsoft-VirtualMachine"
  response_export_values    = null
  schema_validation_enabled = true
  tags                      = {}
  type                      = "Microsoft.Chaos/targets/capabilities@2023-04-15-preview"
}

data "azapi_resource" "vm_shutdown_capability_urn" {
  name                   = azapi_resource.vm_shutdown_capability.name
  parent_id              = azapi_resource.vm_shutdown_capability.parent_id
  type                   = azapi_resource.vm_shutdown_capability.type
  response_export_values = ["properties.urn"]
}

locals {
  vm_shutdown_capability_urn = jsondecode(data.azapi_resource.vm_shutdown_capability_urn.output).properties.urn
}

resource "azurerm_chaos_studio_experiment" "this" {
  location            = azurerm_resource_group.this.location
  name                = "Shutdown-VM"
  resource_group_name = azurerm_resource_group.this.name

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id, ]
  }

  selectors {
    name                    = "Selector1"
    chaos_studio_target_ids = [azapi_resource.chaos_target_vm.id]
  }

  steps {
    name = "Perform-Shutdown"
    branch {
      name = "Execute-Shutdown"
      actions {
        urn           = local.vm_shutdown_capability_urn
        selector_name = "Selector1"
        parameters = {
          abruptShutdown = "false"
        }
        action_type = "continuous"
        duration    = "PT2M"
      }
    }
  }
}
