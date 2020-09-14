provider "google" {
  version = "~>3.1.0"
  project = var.project
  region  = var.region
}


resource "google_compute_instance" "worker" {
  count        = var.instances_count
  name         = "worker-${count.index}"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.app_disk_image
    }
  }

  metadata = {
    ssh-keys = "devops:${file(var.public_key_path)}"
  }
  network_interface {
    network = "default"
    access_config {
      # nat_ip = "{element(google_compute_address.worker-host_ip.*.address, count.index)}"
    }
  }
  tags = ["worker"]
}

resource "google_compute_address" "worker-host_ip" {
  # count = var.instances_count
  name = "worker-host-ip"
}

resource "google_compute_instance" "master" {
  count        = var.master_count
  name         = "master-${count.index}"
  machine_type = "n1-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.app_disk_image
    }
  }

  metadata = {
    ssh-keys = "devops:${file(var.public_key_path)}"
  }
  network_interface {
    network = "default"
    access_config {
      # nat_ip = google_compute_address.csi-host_ip.0.address
    }
  }
  tags = ["master"]
}

resource "google_compute_address" "master-host_ip" {
  # count = var.instances_count
  name = "master-host-ip"
}
