## Terraform module to create a GKE cluster

This module provisions the following resources: 
- A new VPC network with public and private subnets in every availability zone of the specified region
- Routing objects (e.g., cloud router, NAT gateways) to allow the subnets reach Internet
- A Google Kubernetes Engine regional cluster with the following settings:
  - Shielded nodes
  - Private nodes
  - Binary authorization
  - Secret manager
  - Workload identity
  - Security posture set to `basic`
  - Workload vulnerability scanning set to `basic`
  - Private cluster setting (separate CIDR block dedicated for the control plane)
  - DNS endpoint for external traffic
  - Automatic node repair
  - Automatic node upgrade
- 2 node pools for the GKE cluster to be used instead of the default node pool (one on-demand, one spot)
- An IAM membership to give the user identified by the `admin_email` parameter admin access to the GKE cluster
- A service account named "developer" with a `container.clusterViewer` role for the GKE cluster 

## Limitations
- This code aims for an MVP level setup, and thus it only creates RBAC for 1 user; in order to set up RBAC for multiple users,
the GCP project needs to have Organizations set up. That requires verification of either a business domain or a business email,
neither of which the author owns (sorry, I'm basic like that).
- For the same reason as the previous point, this code is meant to be ran from a machine outside of GCP (as opposed to a bastion host inside GCP infra); specifically that means `enable_private_endpoint` setting in the cluster is set to `false` to allow
connection from the Internet, which isn't ideal. If you're planning to use this for real, set up either VPN into your GCP infra,
or a bastion host, and set `enable_private_endpoint` to `true`.

## Assumptions
- You have an active Google Cloud project with administrative privileges to it
- You have enabled API required for Google Cloud Storage, Compute Engine, Kubernetes Engine and IAM
- You have created a GCS bucket
- You are planning to administer the cluster from your laptop (as opposed to a bastion host inside the GCP infra)

## Pre-requisites
- Unix-based terminal (Linux or MacOS)
- gcloud CLI (confirmed working versions listed below)
  - Google Cloud SDK 502.0.0
  - bq 2.1.9
  - core 2024.11.15
  - gcloud-crc32c 1.0.0
  - gke-gcloud-auth-plugin 0.5.9
  - gsutil 5.31
- terraform (confirmed working version 1.5.7 for darwin_amd64; found issues in versions 1.9.8 and 1.10.0 for darwin_amd64)
- terragrunt (confirmed working version 0.23.38)
- kubectl (confirmed working version 1.17.0) with `~/.kube/config` file present in your home dir (see `providers.tf`)
- VSCode (or your code editor of choice with Terraform & Terragrunt extensions installed)

## Instructions

1. Clone this repo to a machine that has software from pre-requisites section set up
2. Locate the Google Cloud project ID, admin user's email address and the bucket name to be used for backend
3. Fill in the values for `project_id` and `admin_email` in the inputs section of terragrunt.hcl (along with any values you wish to override)
4. Fill in the values for `bucket` and `prefix` in `backend "gcs"` section of providers.tf
5. cd to environments/sandbox folder
6. Run the following commands:
   - terragrunt init
   - terragrunt plan
   - terragrunt apply
7. Have a coffee (the wait time is about 10-15 minutes)
8. If no issues came up, run the following command:
   - gcloud container clusters get-credentials <cluster_name> --region <cluster_region>
9. Uncomment the `kubernetes_cluster_role_binding` stanza at the end of main.tf
10. Run `terragrunt apply` one more time to finish the setup

<!-- BEGIN_TF_DOCS -->
## Required Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 6.12.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.public](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_route.public_route](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_subnetwork.private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_router_nat.nat_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_router.nat_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_service_account.kubernetes](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account) | resource |
| [google_container_cluster.gke_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster) | resource |
| [google_container_node_pool.node-pool](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool) | resource |
| [google_project_iam_member.gke_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.developer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_project_iam_member.developer_gke_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [kubernetes_cluster_role_binding.developer_readonly](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | `"us-west1"` | yes |
| <a name="input_admin_email"></a> [admin\_email](#admin\_email) | Admin email | `string` | n/a | yes |
| <a name="vpc_name"></a> [vpc\_name](#vpc\_name) | GCP network name (equivalent of AWS VPC) | `string` | `"sandbox"` | no |
| <a name="public_subnet_cidr"></a> [public\_subnet\_cidr](#public\_subnet\_cidr) | Public subnet CIDR | `string` | n/a | yes |
| <a name="private_subnet_cidr"></a> [private\_subnet\_cidr](#private\_subnet\_cidr) | Private subnet CIDR | `string` | n/a | yes |
| <a name="master_ipv4_cidr_block"></a> [master\_ipv4\_cidr\_block](#master\_ipv4\_cidr\_block) | CIDR block for GKE cluster control plane | `string` | n/a | yes |
| <a name="master_authorized_network_cidr"></a> [master\_authorized\_network\_cidr](#master\_authorized\_network\_cidr) | CIDR block authorized to access the GKE cluster over public Internet | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Kubernetes cluster | `string` | `"sandbox-cluster"` | no |
| <a name="min_master_version"></a> [min\_master\_version](#input\_min\_master\_version) | Minimum version of the cluster | `string` | `"1.31.3-gke.1006000"` | no |
| <a name="input_node_pools_configuration"></a> [node\_pools\_configuration](#input\_node\_pools\_configuration) | Node pool configuration options:<br>{  machine\_type           = string<br>  initial\_node\_count      = number<br>  max\_node\_count      = number<br>  min\_node\_count      = number<br>  auto_repair                = bool<br>  auto_upgrade                = bool<br>  enable_private_nodes                = bool<br>  create_pod_range                = bool<br>  spot                = bool<br>  preemptible                   = bool<br>  enable_secure_boot                   = bool<br>  enable_integrity_monitoring                   = bool<br>  labels                        = map(string)<br>  taint                        = list(object)<br>  oauth\_scopes                  = list(string)<br>}<br><br>Sample usage:<br><br>  node\_pools\_configuration = {<br>    "ondemand" = {<br>      machine_type = "e2-small"<br>      max\_node\_count = 2<br>      min\_node\_count = 1<br>    },<br>    "spot" = {<br>      machine_type = "e2-small"<br>      preemptible = false<br>      spot = true<br>    }<br>  } | `any` | `[]` | yes |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | GKE node machine type | `string` | `"e2-medium"` | no |
| <a name="input_initial_node_count"></a> [initial\_node\_count](#input\_initial\_node\_count) | Initial number of nodes in a node pool | `number` | `1` | no |
| <a name="input_min_node_count"></a> [min\_node\_count](#input\_min\_node\_count) | Minimum number of nodes in the cluster autoscaler PER ZONE (not per node pool) | `number` | `1` | no |
| <a name="input_max_node_count"></a> [max\_node\_count](#input\_max\_node\_count) | Maximum number of nodes in the cluster autoscaler PER ZONE (not per node pool) | `number` | `3` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Disk size for GKE nodes, in GB | `number` | `20` | no |
| <a name="input_auto_repair"></a> [auto\_repair](#input\_auto\_repair) | Repair nodes automatically | `bool` | `true` | no |
| <a name="input_auto_upgrade"></a> [auto\_upgrade](#input\_auto\_upgrade) | Upgrade nodes automatically | `bool` | `true` | no |
| <a name="input_preemptible"></a> [preemptible](#input\_preemptible) | Preemptible nodes; similar to spot instances, but only last up to 24 hours after creation. INCOMPATIBLE WITH spot setting! | `bool` | `false` | no |
| <a name="input_spot"></a> [spot](#input\_spot) | Use spot instances; cheaper than on-demand, but can be interrupted at any time. INCOMPATIBLE WITH preemptible setting! | `bool` | `false` | no |
| <a name="input_enable_secure_boot"></a> [enable\_secure\_boot](#input\_enable\_secure\_boot) | Secure boot helps ensure that the system only runs authentic software by verifying the digital signature of all boot components | `bool` | `true` | no |
| <a name="input_enable_integrity_monitoring"></a> [enable\_integrity\_monitoring](#input\_enable\_integrity\_monitoring) | Enables monitoring and attestation of the boot integrity of the instance | `bool` | `true` | no |
| <a name="input_enable_private_nodes"></a> [enable\_private\_nodes](#input\_enable\_private\_nodes) | Set GKE nodes to only have private IPs | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_cluster_details"></a> [cluster\_details](#output\_cluster\_details) | Details of the kubernetes cluster |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of public subnets |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of private subnets |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | Name of the GKE cluster |
<!-- END_TF_DOCS -->
