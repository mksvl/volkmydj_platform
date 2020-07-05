terraform {
  required_version = ">= 0.12.25"
}
provider "google" {
  version = "3.0.0"
  project = var.project
  region  = var.region
}

resource "google_compute_network" "otus-network" {
  name                    = "otus-network"
  auto_create_subnetworks = true
  routing_mode            = "REGIONAL"
}

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  description   = "otus vpc network"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = "10.17.0.0"
  prefix_length = 16
  network       = google_compute_network.otus-network.id
}

resource "google_service_networking_connection" "otus-connect" {
  network                 = google_compute_network.otus-network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}


resource "google_container_cluster" "cluster-1" {
  name    = "my-gke-cluster"
  network = "otus-network"
  # services_ipv4_cidr       = "10.0.0.0/22"
  # cluster_ipv4_cidr        = "10.0.0.0/16"
  location = var.zone
  #min_master_version       = "1.15.11-gke.13"
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

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }


  addons_config {
    network_policy_config {
      disabled = false
    }
  }

}

resource "google_container_node_pool" "default-pool" {
  name       = "default-pool"
  location   = var.zone
  cluster    = google_container_cluster.cluster-1.name
  node_count = 3
  #version    = "1.15.11-gke.13"
  #min_master_version = "1.15.11-gke.13"

  management {
    auto_upgrade = false
    auto_repair  = true
  }

  autoscaling {
    min_node_count = 3
    max_node_count = 4
  }

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"
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

# resource "google_container_node_pool" "infra-pool" {
#   name       = "infra-pool"
#   location   = var.zone
#   cluster    = google_container_cluster.cluster-1.name
#   node_count = 3
#   version    = "1.15.11-gke.13"
#   #min_master_version = "1.15.11-gke.13"

#   management {
#     auto_upgrade = false
#     auto_repair  = true
#   }

#   autoscaling {
#     min_node_count = 3
#     max_node_count = 5
#   }

#   node_config {
#     preemptible  = true
#     machine_type = "n1-standard-2"
#     disk_size_gb = 20
#     disk_type    = "pd-standard"
#     tags         = var.nodes-tag
#     metadata = {
#       disable-legacy-endpoints = "true"
#     }
#     taint {
#       key    = "node-role"
#       value  = "infra"
#       effect = "NO_SCHEDULE"
#     }

#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#     ]
#   }
# }

# resource "google_compute_firewall" "firewall-gke" {
#   name        = "allow-gke"
#   description = "Alow port for gke"
#   network     = "default"
#   allow {
#     protocol = "tcp"
#     ports    = ["30000-32767"]
#   }
#   direction     = "INGRESS"
#   priority      = "1000"
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = var.nodes-tag
# }
