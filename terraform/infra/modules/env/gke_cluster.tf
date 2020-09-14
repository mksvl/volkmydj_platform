data google_container_engine_versions "engine_versions" {
  location       = var.region
  version_prefix = "1.15."
}


resource "google_container_cluster" "cluster" {
  provider = google-beta
  name     = var.name
  project  = var.project
  # region                   = var.region
  location                 = var.region
  min_master_version       = data.google_container_engine_versions.engine_versions.latest_master_version
  remove_default_node_pool = true
  initial_node_count       = 1
  monitoring_service       = "none"
  logging_service          = "none"


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

resource "google_container_node_pool" "node-pool" {
  project            = var.project
  name               = var.name
  location           = var.region
  cluster            = google_container_cluster.cluster.name
  initial_node_count = 1
  version            = data.google_container_engine_versions.engine_versions.latest_node_version
  #min_master_version = "1.15.11-gke.13"

  management {
    auto_upgrade = false
    auto_repair  = true
  }

  autoscaling {
    min_node_count = var.node_pool_autoscaling_min_node_count
    max_node_count = var.node_pool_autoscaling_max_node_count
  }

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource google_compute_address "address" {
  name         = var.name
  project      = var.project
  region       = var.region
  address_type = "EXTERNAL"
}
