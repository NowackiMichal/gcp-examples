
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "my-vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}

resource "google_compute_instance" "default" {
  name         = "tooling-vm1"
  machine_type = "e2-medium"

  zone = var.zone

  tags = ["tooling-vm-instance"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
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
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3-pip python3-dev",
    ]
    connection {
      type        = "ssh"
      host        = google_compute_address.static.address
      user        = var.user
      timeout     = "500s"
      private_key = file(var.privatekeypath)
     }
  }
  depends_on = [google_compute_firewall.ssh-rule]

 metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${google_compute_address.static.address},' --private-key ${var.privatekeypath} -e 'pub_key=${var.publickeypath}' ./roles/common/tasks/main.yml"
  }
}
resource "google_compute_firewall" "ssh-rule" {
  name    = "tooling-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }
  target_tags   = ["tooling-vm-instance"]
  source_ranges = ["0.0.0.0/0"]
}
# We create a public IP address for our google compute instance to utilize
resource "google_compute_address" "static" {
  name       = "tooling-vm-public-address"
  project    = var.project_id
  region     = var.region
  depends_on = [google_compute_firewall.ssh-rule]
}

