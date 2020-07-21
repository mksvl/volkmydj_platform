variable project {
  type        = string
  description = "Project ID"
  default     = "otus-kuber-278507"
}

variable region {
  type        = string
  description = "Region"
  default     = "europe-west1"
}

variable name {
  type        = string
  description = "Env Name"
  default     = "dev"
}

variable machine_type {
  type        = string
  description = "Worker machine type"
  default     = "e2-standard-2"
}
