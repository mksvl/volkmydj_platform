output cluster_endpoint {
  value       = "${google_container_cluster.cluster.endpoint}"
  description = "Public endpoint cluster"
}

output external_ip_address {
  value       = "${google_compute_address.address.address}"
  description = "External IP address"
}
