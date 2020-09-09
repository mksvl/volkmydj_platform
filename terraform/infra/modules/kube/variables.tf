variable project {
  description = "Project ID"
}

variable name {
  type        = string
  description = "Env Name"
}


variable region {
  default     = "europe-west1"
  description = "Region"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable app_disk_image {
  default     = "csi-host"
  description = "Disk Image"
}

variable private_key {
  description = "Path to the private key used for ssh access"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable users {
  default     = ["devops"]
  description = "Users"
}


variable instances_count {
  type        = number
  default     = 3
  description = "Count"
}
