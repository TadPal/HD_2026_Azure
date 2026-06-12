variable "resource_group_location" {
  type        = string
  default     = "swedencentral"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type    = string
  default = "aks-resource-group"
}

variable "cluster_name" {
  type    = string
  default = "uois-cluster"
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 1 # DEV - 1, PROD - 3
}

variable "systempool_node_count" {
  type        = number
  description = "The initial quantity of nodes for system node pool."
  default     = 1 # DEV - 1, PROD - 2
}


variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "manifests_path" {
  type        = string
  default     = "../UOIS/kubernetes/manifests"
  description = "The relative path from the terraform directory to the Kubernetes manifests."
}

variable "config_path" {
  type        = string
  default     = "../UOIS/kubernetes"
  description = "The relative path from the terraform directory to the Kubernetes manifests."
}

variable "db_password" {
  type        = string
  description = "PostgreSQL Admin Password"
  sensitive   = true
}

variable "b64_backup_ssh_key" {
  type        = string
  description = "Base64 encoded SSH Key for backup server uploads"
  sensitive   = true
}

variable "agent_vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size"
}