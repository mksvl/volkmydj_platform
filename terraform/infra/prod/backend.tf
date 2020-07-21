terraform {
  backend gcs {
    bucket = "kuber-bucket-prod"
    prefix = "terraform/state"
  }
}
