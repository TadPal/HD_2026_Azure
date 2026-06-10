# --- 1. Central Log Repository ---
resource "azurerm_log_analytics_workspace" "law" {
  name                = "uois-centralni-logy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- 2. Enable Sentinel on the Workspace ---
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
  workspace_id = azurerm_log_analytics_workspace.law.id
}

# --- 3. Route Control Plane Logs to Sentinel ---
resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "roury-do-siemu-tf"
  target_resource_id         = azurerm_kubernetes_cluster.k8s.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { 
    category = "kube-audit" 
  }
  enabled_log { 
    category = "kube-apiserver" 
  }

  metric {
    category = "AllMetrics"
    enabled  = false
  }
}

# --- 4. Sentinel Alert Rule ---
resource "azurerm_sentinel_alert_rule_scheduled" "k8s_alert" {
  name                       = "4556b92e-a8a1-4b24-a71e-ae7ad6c7f932"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.sentinel.workspace_id
  display_name               = "UOIS - Hlídač bezpečnostních příkazů"
  severity                   = "High"
  query                      = <<-EOT
    AzureDiagnostics
    | where Category == "kube-audit"
    | extend log_s = columnifexists("log_s", "")
    | where log_s has "delete" or log_s has "exec"
    | project TimeGenerated, Category, ResourceId, log_s
  EOT
  query_frequency            = "PT5M"   # Run every 5 minutes
  query_period               = "PT1H"   # Look back 1 hour
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
}