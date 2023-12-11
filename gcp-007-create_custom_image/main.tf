resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}
resource "google_compute_firewall" "ssh-rule" {
  name    = "demo-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["demo-instance-template"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "static" {
  name       = "vm-public-address"
  project    = var.project_id
  region     = var.region
  depends_on = [google_compute_firewall.ssh-rule]
}
resource "google_compute_instance" "default" {
  provider     = google-beta
  project      = var.project_id
  name         = "test-vm1"
  machine_type = "e2-medium"

  zone = var.zone

  tags = ["demo-instance-template"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

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
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
}

resource "google_compute_machine_image" "image" {
  provider        = google-beta
  project         = var.project_id
  name            = "demo-custom-machine-image"
  source_instance = google_compute_instance.default.self_link
}
