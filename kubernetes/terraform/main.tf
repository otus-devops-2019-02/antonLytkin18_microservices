provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"
}

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"

  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    kubernetes_dashboard {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = "10"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_firewall" "firewall_nodeport" {
  name    = "kube-app-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}
