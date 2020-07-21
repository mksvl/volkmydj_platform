variable project {
  type        = string
  description = "Project ID"
}

variable region {
  type        = string
  description = "Region"
  default     = "europe-west4"
}

variable name {
  type        = string
  description = "Env Name"
}

variable machine_type {
  type        = string
  description = "Worker machine type"
  default     = "e2-standard-2"
}
