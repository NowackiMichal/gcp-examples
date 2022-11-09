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

data "google_storage_transfer_project_service_account" "default" {
  
}
output "default_account" {
  value = data.google_storage_transfer_project_service_account.default.email
}
resource "google_storage_bucket" "google-bucket" {
  name          = "${var.project_id}-bucket-1"
  storage_class = "NEARLINE"
  location      = var.region
}
resource "google_storage_bucket" "google-backup-bucket" {
  name          = "${var.project_id}-backup"
  storage_class = "NEARLINE"
  location      = var.region
}
resource "google_storage_bucket_iam_member" "google-backup-bucket-iam" {
  bucket     = google_storage_bucket.google-backup-bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [google_storage_bucket.google-backup-bucket]
}
resource "google_storage_bucket_iam_member" "google-bucket-iam" {
  bucket     = google_storage_bucket.google-bucket.name
  role       = "roles/storage.admin"
  member     = "serviceAccount:${data.google_storage_transfer_project_service_account.default.email}"
  depends_on = [google_storage_bucket.google-bucket]
}
resource "google_storage_transfer_job" "google-bucket-afternoon-backup" {
  description = "Afternoon backup of Google bucket"
  project     = "${var.project_id}"

  transfer_spec {
    transfer_options {
      delete_objects_unique_in_sink = false
    }
    gcs_data_source {
      bucket_name = google_storage_bucket.google-bucket.name
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.google-backup-bucket.name
      # path        = "foo/bar/"    # optional 
    }
  }

  schedule {
    schedule_start_date {
      year  = 2022
      month = 10
      day   = 20
    }
    schedule_end_date {
      year  = 2022
      month = 12
      day   = 31
    }
    start_time_of_day {
      hours   = 6
      minutes = 00
      seconds = 0
      nanos   = 0
    }
    repeat_interval = "604800s" # weekly
  }

  depends_on = [google_storage_bucket_iam_member.google-backup-bucket-iam]
}