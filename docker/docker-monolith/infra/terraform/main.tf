provider "google" {
  version = "2.0.0"

  project = "${var.project}"
  region  = "europe-west1"
}

resource "google_compute_instance" "app" {
  name         = "reddit-app-${count.index}"
  machine_type = "f1-micro"
  zone         = "${var.zone}"
  tags         = ["reddit-app"]
  count        = "${var.count}"

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
    }
  }

  network_interface {
    network = "default"
    access_config = {}
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    user  = "appuser"
    agent = false
    private_key = "${file(var.private_key_path)}"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["reddit-app"]
}
