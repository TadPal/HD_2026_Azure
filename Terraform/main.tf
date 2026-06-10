resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "uois-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "postgres_subnet" {
  name                 = "postgres-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "pg-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_link" {
  name                  = "pg-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "uois-db-${azurerm_resource_group.rg.name}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  delegated_subnet_id    = azurerm_subnet.postgres_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id
  administrator_login    = "postgres"
  administrator_password = var.db_password
  sku_name               = "GP_Standard_D2s_v3"
  storage_mb             = 32768

  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [
      zone,
      high_availability
    ]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.pg_link]
}

resource "azurerm_postgresql_flexible_server_database" "data" {
  name      = "data"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "credentials" {
  name      = "credentials"
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "uois-aks"

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "systempool"
    vm_size        = var.agent_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
    zones          = ["1", "2", "3"]
    # enable_auto_scaling = true
    # min_count           = var.node_count
    # max_count           = 3
    node_count                   = var.node_count
    only_critical_addons_enabled = true
  }

  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.34"
    pod_cidr            = "192.168.0.0/16"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.law.id
    msi_auth_for_monitoring_enabled = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id # Vazba na cluster výše
  vm_size               = var.agent_vm_size
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  mode                  = "User"
  os_type               = "Linux"
  zones                 = ["1", "2", "3"]

  enable_auto_scaling = true
  min_count           = var.node_count
  max_count           = 2
}

resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_kubernetes_cluster.k8s.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.k8s.oms_agent[0].oms_agent_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.k8s]
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-basic"
  create_namespace = true

  depends_on = [azurerm_kubernetes_cluster.k8s]

  set = [{
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }]
}

data "kubernetes_service_v1" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-basic"
  }

  depends_on = [helm_release.ingress_nginx]
}

resource "kubernetes_config_map_v1" "common_env" {
  metadata {
    name      = "common-env"
    namespace = "default"
  }

  data = merge(
    {
      for line in split("\n", file("${var.config_path}/common.env")) :
      trimspace(split("=", line)[0]) => trimspace(split("=", line)[1])
      if length(trimspace(line)) > 0 && !startswith(line, "#")
    },
    {
      POSTGRES_HOST = "${azurerm_postgresql_flexible_server.db.fqdn}:5432"
      POSTGRES_USER = azurerm_postgresql_flexible_server.db.administrator_login
    }
  )

  depends_on = [azurerm_kubernetes_cluster.k8s, azurerm_postgresql_flexible_server.db]
}

resource "kubernetes_secret_v1" "db_secrets" {
  metadata {
    name      = "db-secrets"
    namespace = "default"
  }

  data = {
    POSTGRES_PASSWORD = var.db_password
    SSH_PRIVATE_KEY   = var.b64_backup_ssh_key
  }

  type = "Opaque"

  depends_on = [azurerm_kubernetes_cluster.k8s]
}

resource "kubectl_manifest" "deploy_all" {
  for_each  = fileset(var.manifests_path, "*.yaml")
  yaml_body = file("${var.manifests_path}/${each.value}")

  depends_on = [
    helm_release.ingress_nginx,
    azurerm_kubernetes_cluster.k8s,
    kubernetes_config_map_v1.common_env,
    kubernetes_secret_v1.db_secrets,
  ]
}