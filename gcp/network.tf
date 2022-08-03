resource "google_compute_network" "baffles_k3s_network" {
  name                    = "baffles-${var.name}-k3s-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "baffles_k3s_subnetwork" {
  name          = "baffles-${var.name}-k3s-subnetwork"
  region        = var.region
  network       = google_compute_network.baffles_k3s_network.self_link
  ip_cidr_range = "192.168.1.0/24"
}

resource "google_compute_firewall" "k3s_internal" {
  name    = "baffles-${var.name}-k3s-allow-internal"
  network = google_compute_network.baffles_k3s_network.name
  allow {
    protocol = "all"
  }
  source_tags = ["k3s"]
  target_tags = ["k3s"]
}

resource "google_compute_firewall" "baffles_k3s_firewall" {
  name    = "baffles-${var.name}-k3s-firewall"
  network = google_compute_network.baffles_k3s_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "30000-32767"]
  }

  target_tags   = ["k3s"]
  source_ranges = ["0.0.0.0/0"]
}
