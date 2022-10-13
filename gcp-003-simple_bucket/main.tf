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


resource "google_storage_bucket" "gcp_bucket-1" {
  name          = "${var.project_id}-bucket-1"
  location      = var.region
  force_destroy = true # default = false
  
  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
  versioning {
    enabled = true
  }

}
resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.gcp_bucket-1.name
  role   = "READER"
  entity = "allUsers"
}
resource "google_storage_bucket_object" "object" {
  name   = "red-space.jpg"
  bucket = google_storage_bucket.gcp_bucket-1.name
  source = "images/red-space.jpg"
}
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.object.output_name
  bucket = google_storage_bucket.gcp_bucket-1.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_kms_key_ring" "keyring" {
  name     = "${var.project_id}-key-ring"
  location = "europe-central2"
}
resource "google_kms_crypto_key" "sign-key" {
  name     = "${var.project_id}-gen-key"
  key_ring = google_kms_key_ring.keyring.id
}