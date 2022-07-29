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

resource "google_compute_firewall" "baffles_k3s_firewall" {
  name    = "baffles-${var.name}-k3s-firewall"
  network = google_compute_network.baffles_k3s_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  target_tags   = ["k3s"]
  source_ranges = ["0.0.0.0/0"]
}
