provider "google" {
  project = var.project
  region  = var.region
  version = "~> 3.16"
}


resource "google_storage_bucket" "kuber-bucket-dev" {
  name               = "kuber-bucket-dev"
  location           = "US"
  force_destroy      = true
  bucket_policy_only = true
}


output storage-bucket_url-kuber-dev {
  value = "${google_storage_bucket.kuber-bucket-dev.url}"
}
