terraform {
  required_version = "~>0.12"
}

provider "google-beta" {
  version = "~>3.1.0"
  project = var.project
  region  = var.region
}

provider "google" {
  version = "~>3.1.0"
  project = var.project
  region  = var.region
}

module prod_env {
  source                               = "../../modules/env"
  project                              = var.project
  region                               = var.region
  name                                 = var.name
  node_pool_autoscaling_min_node_count = 2
  node_pool_autoscaling_max_node_count = 2
  machine_type                         = var.machine_type
}
