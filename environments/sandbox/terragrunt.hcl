terraform {
  source = "../..//modules/gcp/sandbox"
}

inputs = {
  #admin_email    = "<YOUR_ADMIN_EMAIL>"
  #project_id     = "<YOUR_GCP_PROJECT_ID>"
  #region         = "<REGION>"

  #vpc_name            = "<VPC_NAME>"
  public_subnet_cidr  = "<PUBLIC_CIDR>/20"
  private_subnet_cidr = "<PRIVATE_CIDR>/20"
  
  #cluster_name           = "<CLUSTER_NAME>"
  enable_private_nodes           = true
  master_ipv4_cidr_block         = "<CONTROL_PLANE_CIDR>/28"
  #master_authorized_network_cidr = "<AUTHORIZED_ACCESS_CIDR>"
  
  node_pools_configuration = {
    "ondemand" = {      
      machine_type                = "e2-small"
      initial_node_count          = 1
      max_node_count              = 2
      min_node_count              = 1
      disk_size_gb                = 100
      auto_repair                 = true
      auto_upgrade                = true
      spot                        = false
      preemptible                 = false
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      enable_private_nodes        = true

      labels = {
        role = "general"
      }
    },
    "spot" = {
      machine_type                = "e2-small"
      initial_node_count          = 1
      max_node_count              = 2
      min_node_count              = 1
      disk_size_gb                = 20
      auto_repair                 = true
      auto_upgrade                = true
      spot                        = true
      preemptible                 = false
      enable_secure_boot          = true
      enable_integrity_monitoring = true
      enable_private_nodes        = true

      labels = {
        role = "auxillary"
      }

      taint = [
        {
          key    = "instance_type"
          value  = "spot"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}




