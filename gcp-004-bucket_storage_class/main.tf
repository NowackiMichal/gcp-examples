terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.34.0"
    }
  }
}

provider "google" {
  # Configuration options

  project = var.project_id
  region  = var.region
  zone    = var.zone
}


resource "google_storage_bucket" "gcp_bucket-a" {
  name          = "${var.project_id}-bucket-a"
  location      = var.region
  force_destroy = true # default = false
  
  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }
  
}