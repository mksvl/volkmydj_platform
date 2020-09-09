provider "google" {
  version = "~>3.1.0"
  project = var.project
  region  = var.region
}


resource "google_compute_instance" "csi-host" {
  count        = var.instances_count
  name         = "${var.name}${count.index}"
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
      # nat_ip = google_compute_address.csi-host_ip.0.address
    }
  }
  tags = ["csi-host"]
}

resource "google_compute_address" "csi-host_ip" {
  # count = var.instances_count
  name = "csi-host-ip"
}
