resource "azurerm_log_analytics_workspace" "this" {
  name                = "chaos-loganalytics"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

locals {
  extension_settings           = "{ \"workspaceId\": \"${azurerm_log_analytics_workspace.this.workspace_id}\" }"
  extension_protected_settings = "{ \"workspaceKey\": \"${azurerm_log_analytics_workspace.this.primary_shared_key}\" }"
}

resource "azurerm_virtual_machine_extension" "da" {
  name                       = "DAExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true
  settings                   = local.extension_settings
  protected_settings         = local.extension_protected_settings
  depends_on                 = [azurerm_virtual_machine_extension.AzureMonitorLinuxAgent]
}

resource "azurerm_log_analytics_solution" "insights" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
}

resource "azurerm_virtual_machine_extension" "AzureMonitorLinuxAgent" {
  name                       = "AzureMonitorLinuxAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
}

resource "azurerm_monitor_data_collection_rule" "this" {
  name                = "vm-collection-rules"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      name                  = "vm-collection-log"
    }

    azure_monitor_metrics {
      name = "vm-collection-metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["vm-collection-log"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }
  }
  depends_on = [
    azurerm_virtual_machine_extension.AzureMonitorLinuxAgent,
    azurerm_virtual_machine_extension.da
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  name                    = "vm-collection-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id
  description             = "vm-collection"
}