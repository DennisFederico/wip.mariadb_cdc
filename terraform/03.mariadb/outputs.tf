output "mariadb" {
  value = [ for compute in google_compute_instance.mariadb_instance[*] : "${compute.name}:${compute.network_interface.0.network_ip} / ${compute.network_interface.0.access_config.0.nat_ip}" ]  
}
