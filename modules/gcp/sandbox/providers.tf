provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

terraform {
  backend "gcs" {
    bucket = #"<YOUR_BUCKET_NAME>"
    prefix = "sandbox/terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }
  }
}
