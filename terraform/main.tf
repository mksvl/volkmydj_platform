terraform {
  required_version = ">= 0.12.8"
}
provider "google" {
  version = "3.0.0"
  project = var.project
  region  = var.region
}



resource "google_container_cluster" "cluster-1" {
  name                     = "my-gke-cluster"
  location                 = var.zone
  min_master_version       = "1.15.11-gke.13"
  remove_default_node_pool = true
  initial_node_count       = 1
  enable_legacy_abac       = true
  monitoring_service       = "none"
  logging_service          = "none"


  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }


  addons_config {
    network_policy_config {
      disabled = false
    }
  }

}

resource "google_container_node_pool" "reddit_app-pool" {
  name       = "my-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.cluster-1.name
  node_count = 1
  version    = "1.15.11-gke.13"
  #min_master_version = "1.15.11-gke.13"

  management {
    auto_upgrade = false
    auto_repair  = true
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    tags         = var.nodes-tag
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_firewall" "firewall-gke-reddit" {
  name        = "allow-reddit-gke"
  description = "Alow port for gke-reddit"
  network     = "default"
  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }
  direction     = "INGRESS"
  priority      = "1000"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.nodes-tag
}
