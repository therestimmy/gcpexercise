output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = [for subnet in google_compute_subnetwork.public : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value = [for subnet in google_compute_subnetwork.private : subnet.id]
}

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke_cluster.name
}
