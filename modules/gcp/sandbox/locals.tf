locals {
 node_pools_configuration = { for id, attributes in var.node_pools_configuration :
   id => {
     machine_type                = lookup(attributes, "machine_type", var.machine_type)
     initial_node_count          = lookup(attributes, "initial_node_count", var.initial_node_count)
     max_node_count              = lookup(attributes, "max_node_count", var.max_node_count)
     min_node_count              = lookup(attributes, "min_node_count", var.min_node_count)
     disk_size_gb                = lookup(attributes, "disk_size_gb", var.disk_size_gb)
     auto_repair                 = lookup(attributes, "auto_repair", true)
     auto_upgrade                = lookup(attributes, "auto_upgrade", true)
     enable_private_nodes        = lookup(attributes, "enable_private_nodes", true)
     spot                        = lookup(attributes, "spot", var.spot)
     preemptible                 = lookup(attributes, "preemptible", var.preemptible)
     enable_secure_boot          = lookup(attributes, "enable_secure_boot", var.enable_secure_boot)
     enable_integrity_monitoring = lookup(attributes, "enable_integrity_monitoring", var.enable_integrity_monitoring)
     labels                      = lookup(attributes, "labels", {})
     taint                       = lookup(attributes, "taint", [])
     oauth_scopes                = ["https://www.googleapis.com/auth/cloud-platform"]
   }
 }
}
