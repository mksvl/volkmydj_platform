terraform {
  backend "gcs" {
    bucket = "kuber-bucket-dev"
    prefix = "terraform/state"
  }
}
