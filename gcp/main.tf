terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.28.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance" "k3s_controlplane_instance" {
  name         = "k3s-controlplane"
  machine_type = "n1-standard-1"
  tags         = ["k3s", "k3s-controlplane"]

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-8-optimized-gcp"
    }
  }

  network_interface {
    network = "default"

    access_config {
    }
  }

  advanced_machine_features {
    enable_nested_virtualization = true
  }

  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }

  # Dummy provisioner to ensure that ssh connection actually works
  provisioner "remote-exec" {
    inline = [
      "cat /etc/os-release",
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(pathexpand("~/.ssh/google_compute_engine"))
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "local-exec" {
    command = <<EOT
            k3sup install \
            --ip ${self.network_interface[0].access_config[0].nat_ip} \
            --context k3s \
            --ssh-key ~/.ssh/google_compute_engine \
            --user $(whoami) \
            --k3s-extra-args '--no-deploy -traefik'
        EOT
  }

  depends_on = [
    google_compute_firewall.k3s_firewall,
  ]
}

resource "google_compute_instance" "k3s_agent_instance" {
  count        = var.agent_nums
  name         = "k3s-agent-${count.index}"
  machine_type = "n1-standard-1"
  tags         = ["k3s"]

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-8-optimized-gcp"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  advanced_machine_features {
    enable_nested_virtualization = true
  }

  # Dummy provisioner to ensure that ssh connection actually works
  provisioner "remote-exec" {
    inline = [
      "cat /etc/os-release",
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(pathexpand("~/.ssh/google_compute_engine"))
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  provisioner "local-exec" {
    command = <<EOT
            k3sup join \
            --ip ${self.network_interface[0].access_config[0].nat_ip} \
            --server-ip ${google_compute_instance.k3s_controlplane_instance.network_interface[0].access_config[0].nat_ip} \
            --ssh-key ~/.ssh/google_compute_engine \
            --user $(whoami)
        EOT
  }

  depends_on = [
    google_compute_firewall.k3s_firewall,
  ]
}

resource "google_compute_firewall" "k3s_firewall" {
  name    = "k3s-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  target_tags = ["k3s"]
  source_tags = ["k3s"]
}
