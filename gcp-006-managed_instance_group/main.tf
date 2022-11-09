resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}

resource "google_compute_autoscaler" "demo_autoscaler" {
  name   = "${var.project_id}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.my_igm.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_template" "instance_template" {
  name           = "${var.project_id}-instance-template"
  machine_type   = "e2-medium"
  can_ip_forward = false

  tags = ["demo-instance-template"]

  disk {
    source_image = data.google_compute_image.debian.id
  }

  network_interface {
    network = google_compute_network.vpc_network.name
  }

  metadata = {
    key = "demo"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_target_pool" "target_pool" {
  name = "my-target-pool"
}

resource "google_compute_instance_group_manager" "my_igm" {
  name = "${var.project_id}-igm"
  zone = var.zone

  version {
    instance_template  = google_compute_instance_template.instance_template.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.target_pool.id]
  base_instance_name = "${var.project_id}-demo"
}

data "google_compute_image" "debian" {
  family  = "debian-11"
  project = "debian-cloud"
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