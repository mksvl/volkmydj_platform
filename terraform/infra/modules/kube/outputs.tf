output "worker_external_ip" {
  value = join(
    " ",
    google_compute_instance.worker.*.network_interface.0.access_config.0.nat_ip,
  )
}

output "master_external_ip" {
  value = join(
    " ",
    google_compute_instance.master.*.network_interface.0.access_config.0.nat_ip,
  )
}
