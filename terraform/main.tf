terraform {
  required_version = ">= 0.12.28"
}

data google_container_engine_versions "engine_versions" {
  location       = var.region
  version_prefix = "1.16."
}


resource "google_container_cluster" "cluster-1" {
  provider                 = google-beta
  name                     = "my-gke-cluster"
  project                  = var.project
  region                   = var.region
  location                 = var.zone
  min_master_version       = data.google_container_engine_versions.latest_master_version
  remove_default_node_pool = true
  initial_node_count       = 1
  # enable_legacy_abac       = true
  monitoring_service = "none"
  logging_service    = "none"


  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
    istio_config {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "default-pool" {
  project    = var.project
  name       = "default-pool"
  location   = var.zone
  cluster    = google_container_cluster.cluster-1.name
  node_count = 4
  version    = data.google_container_engine_versions.engine_versions.latest_node_version
  #min_master_version = "1.15.11-gke.13"

  management {
    auto_upgrade = false
    auto_repair  = true
  }

  autoscaling {
    min_node_count = 4
    max_node_count = 5
  }

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"
    disk_size_gb = 20
    disk_type    = "pd-standard"
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource google_compute_address "address" {
  name         = "gke-cluster-ip"
  project      = var.project
  region       = var.region
  address_type = "EXTERNAL"
}
