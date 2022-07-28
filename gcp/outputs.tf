output "k3s_ip" {
  value = google_compute_instance.k3s_controlplane_instance.network_interface.0.access_config.0.nat_ip
}
