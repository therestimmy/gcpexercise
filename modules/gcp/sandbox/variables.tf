variable "project_id" {
  description = "Google project ID to create resources in"
  type        = string
}

variable "region" {
  description = "The region for the GCP resources"
  type        = string
  default     = "us-west1"
}

variable "admin_email" {
  description = "The email of admin user to be used for GKE access"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "sandbox"
}

variable "public_subnet_cidr" {
  description = "List of public subnets (should cover all AZs)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "List of private subnets (should cover all AZs)"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for control plane; use this only if you're configuring a private cluster"
  type        = string
}

variable "master_authorized_network_cidr" {
  description = "CIDR block authorized to access the GKE cluster over public Internet"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "sandbox-cluster"
}

variable "min_master_version" {
  description = "Minimum version of the master"
  type        = string
  default     = "1.31.3-gke.1006000"
}

variable "node_pools_configuration" {
  type = any

  description = <<-EOT
    Node pool configuration options:
    {
      machine_type                = string
      initial_node_count          = number
      max_node_count              = number
      min_node_count              = number
      auto_repair                 = bool
      auto_upgrade                = bool
      enable_private_nodes        = bool
      create_pod_range            = bool
      spot                        = bool
      preemptible                 = bool
      enable_secure_boot          = bool
      enable_integrity_monitoring = bool
      labels                      = map(string)
      taint                       = list(object)
      oauth_scopes                = list(string)
    }
    EOT
  default = []
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "initial_node_count" {
  description = "Initial number of nodes in a node pool"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes in the cluster autoscaler PER ZONE (not per node pool)"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the cluster autoscaler PER ZONE (not per node pool)"
  type        = number
  default     = 3
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes, in GB"
  type        = number
  default     = 20
}

variable "auto_repair" {
  description = "Repair nodes automatically"
  type        = bool 
  default     = true
}

variable "auto_upgrade" {
  description = "Upgrade nodes automatically"
  type        = bool
  default     = true
}

variable "preemptible" {
  description = "Preemptible nodes; similar to spot instances, but only last up to 24 hours after creation. INCOMPATIBLE WITH spot setting!"
  type        = bool
  default     = false
}

variable "spot" {
  description = "Use spot instances; cheaper than on-demand, but can be interrupted at any time. INCOMPATIBLE WITH preemptible setting!"
  type        = bool
  default     = false
}

variable "enable_secure_boot" {
  description = "Secure boot helps ensure that the system only runs authentic software by verifying the digital signature of all boot components"
  type        = bool
  default     = true
}

variable "enable_integrity_monitoring" {
  description = "Enables monitoring and attestation of the boot integrity of the instance"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Set GKE nodes to only have private IPs"
  type        = bool
  default     = false
}