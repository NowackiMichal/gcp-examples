resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-network-02"
  auto_create_subnetworks = true
  mtu                     = 1460
}
resource "google_compute_firewall" "ssh-rule" {
  name    = "demo-ssh-02"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["demo-instance-template"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "static" {
  name       = "vm-public-address-02"
  project    = var.project_id
  region     = var.region
  depends_on = [google_compute_firewall.ssh-rule]
}
resource "google_compute_instance_from_machine_image" "default" {
  provider     = google-beta
  project      = var.project_id
  name         = "test-vm-from-custom-machine-image"
  machine_type = "e2-medium"
  source_machine_image = "projects/${var.project_id}/global/machineImages/demo-custom-machine-image"
  zone = var.zone

  tags = ["demo-instance-template"]

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = var.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_firewall.ssh-rule]

  metadata = {
    
    foo = "bar"
  }
}
