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

variable disk_type {
  type        = string
  description = "Worker disk type"
  default     = "pd-standard"
}

variable disk_size_gb {
  type        = number
  description = "Disk size"
  default     = 20
}

variable node_pool_autoscaling_min_node_count {
  description = "Minimum nodes count for autoscalling"
  type        = number
  default     = 1
}

variable node_pool_autoscaling_max_node_count {
  description = "Maximum nodes count for autoscalling"
  type        = number
  default     = 1
}



# #variable zone {
# #  type        = string
# #  description = "Zone"
# #}

# variable nodes-tag {
#   type        = list(string)
#   description = "List of nodes tags"
# }

# variable port-list {
#   type        = list(string)
#   description = "Allowed application ports"
# }
