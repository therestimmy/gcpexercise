###########################################
# Definitions of VPC and network resources
###########################################

data "google_compute_zones" "available" {
  region = var.region
}

data "google_client_config" "default" {}

resource "google_compute_network" "vpc" {
  name                     = var.vpc_name
  auto_create_subnetworks  = false
  project                  = var.project_id
}

# Public subnets
resource "google_compute_subnetwork" "public" {
  for_each      = toset(data.google_compute_zones.available.names)
  region        = var.region
  name          = "public-subnet-${each.key}"
  ip_cidr_range = cidrsubnet(var.public_subnet_cidr, 4, index(data.google_compute_zones.available.names, each.key))
  network       = google_compute_network.vpc.id
}

# Route for public subnets to the GCP-provided Internet gateway
resource "google_compute_route" "public_route" {
  for_each        = google_compute_subnetwork.public
  name            = "${var.vpc_name}-public-route-${each.key}"
  network         = google_compute_network.vpc.self_link
  dest_range      = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority        = 1000
}

# Private subnets
resource "google_compute_subnetwork" "private" {
  for_each      = toset(data.google_compute_zones.available.names)
  region        = var.region
  name          = "private-subnet-${each.key}"
  network       = google_compute_network.vpc.id
  ip_cidr_range = cidrsubnet(var.private_subnet_cidr, 4, index(data.google_compute_zones.available.names, each.key))
  private_ip_google_access = true
}

# NAT gateways for each private subnet
resource "google_compute_router_nat" "nat_gateway" {
  name    = "${var.vpc_name}-nat-gateway"
  router     = google_compute_router.nat_router.name
  region     = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  dynamic "subnetwork" {
    for_each = google_compute_subnetwork.private
      content {
        name = subnetwork.value.self_link
        source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
      }
  }
}

# Cloud router for NAT gateways
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-nat-router"
  network = google_compute_network.vpc.self_link
  region  = var.region
}

################# GKE STUFF ########################
# Definitions of GKE cluster resources
####################################################

resource "google_service_account" "kubernetes" {
  account_id   = "kubernetes"
  display_name = "kubernetes"
}

resource "google_container_cluster" "gke_cluster" {
  name                = var.cluster_name
  location            = var.region
  network             = google_compute_network.vpc.id
  subnetwork          = tostring(google_compute_subnetwork.private["${data.google_compute_zones.available.names[0]}"].id)
  min_master_version  = "latest"

  # Set up a regional cluster to span all private subnets
  node_locations = toset(data.google_compute_zones.available.names)

  # Security section 

  # Shielded nodes and binary authorization; shielded nodes are true by default, but the docs don't say in which GKE versions
  enable_shielded_nodes = true
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
  # Enable workload_identity_config.workload_pool in order to enable Secrets Manager
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  # Enable secret manager integration
  secret_manager_config {
    enabled = true
  }
  # Enable security posture settings
  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }  
  # Enable private nodes, designate a separate CIDR block for the control plane
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = var.enable_private_nodes
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }
  # Add a DNS endpoint and set it to be accessible externally because we don't have a bastion host 
  # to manage this cluster  
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }
  # Add an authorized network CIDR that is allowed to access the cluster over public internet
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_network_cidr
      display_name = "master_authorized_cidr"
    }
  }

  # Remove the default node pool in favor of google_container_node_pool config below
  initial_node_count       = var.initial_node_count
  remove_default_node_pool = true

  deletion_protection      = false

  depends_on = [
    google_compute_subnetwork.private,
    google_service_account.kubernetes
  ]
}

# Dynamically created node pools 
resource "google_container_node_pool" "node-pool" {
  for_each = local.node_pools_configuration

  name               = "${var.cluster_name}-${each.key}"
  cluster            = google_container_cluster.gke_cluster.id
  node_locations     = toset(data.google_compute_zones.available.names)
  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  network_config {
    enable_private_nodes = each.value.enable_private_nodes
  }

  node_config {
    spot         = each.value.spot
    preemptible  = each.value.preemptible
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb

    # Shielded node config
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    } 

    labels = each.value.labels
    dynamic "taint" {
      for_each = each.value.taint
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    service_account = google_service_account.kubernetes.email
    oauth_scopes    = each.value.oauth_scopes
  }
}

# Grant admin access to the GKE cluster to a single user
resource "google_project_iam_member" "gke_admin" {
  project = var.project_id
  role    = "roles/container.admin" 
  member  = "user:${var.admin_email}" 
}

# Read-only service account for developers and such
resource "google_service_account" "developer" {
  account_id   = "developer"
  display_name = "Developer Service Account"
}

resource "google_project_iam_member" "developer_gke_access" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.developer.email}"
}

# Set up RBAC to bind the developer SA to the Kube 'view' role
# Uncomment this part AFTER configuring cluster credentials
#resource "kubernetes_cluster_role_binding" "developer_readonly" {
#  metadata {
#    name = "developer-readonly-binding"
#  }
#
#  role_ref {
#    api_group = "rbac.authorization.k8s.io"
#    kind      = "ClusterRole"
#    name      = "view"
#  }
#
#  subject {
#    kind      = "ServiceAccount"
#    name      = "developer"
#    namespace = "default"
#  }
#  depends_on = [
#    google_container_cluster.gke_cluster
#  ]
#}
