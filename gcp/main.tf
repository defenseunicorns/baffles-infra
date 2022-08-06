resource "google_compute_disk" "control_plane_disk" {
  name = "baffles-${var.name}-control-plane-disk"
  size = var.disk_size
}

resource "google_compute_instance" "k3s_controlplane_instance" {
  name         = "baffles-${var.name}-k3s-controlplane"
  machine_type = "n1-standard-1"
  tags         = ["k3s", "k3s-controlplane"]

  boot_disk {
    initialize_params {
      image = "baffles-debian11"
    }
  }

  attached_disk {
    source = "${google_compute_disk.control_plane_disk.name}"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.baffles_k3s_subnetwork.name

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

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand("~/.ssh/google_compute_engine"))
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/files/usr.sbin.libvirtd"
    destination = "/tmp/usr.sbin.libvirtd"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/setup.sh"
  }

  provisioner "local-exec" {
    command = <<EOT
            k3sup install \
            --ip ${self.network_interface[0].access_config[0].nat_ip} \
            --context k3s \
            --ssh-key ~/.ssh/google_compute_engine \
            --user $(whoami) \
            --k3s-extra-args '--service-node-port-range=30000-32767'
        EOT
  }

  depends_on = [
    google_compute_firewall.baffles_k3s_firewall,
  ]
}

resource "google_compute_disk" "agent_disk" {
  count = var.agent_nodes
  name = "baffles-${var.name}-agent-disk-${count.index}"
  size = var.disk_size
}

resource "google_compute_instance" "k3s_agent_instance" {
  count        = var.agent_nodes
  name         = "baffles-${var.name}-k3s-agent-${count.index}"
  machine_type = "n1-standard-1"
  tags         = ["k3s"]

  boot_disk {
    initialize_params {
      image = "baffles-debian11"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.agent_disk.*.self_link, count.index)}"
    device_name = "${element(google_compute_disk.agent_disk.*.name, count.index)}"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.baffles_k3s_subnetwork.name

    access_config {}
  }

  advanced_machine_features {
    enable_nested_virtualization = true
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(pathexpand("~/.ssh/google_compute_engine"))
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    source      = "${path.module}/files/usr.sbin.libvirtd"
    destination = "/tmp/usr.sbin.libvirtd"
  }

  provisioner "remote-exec" {
    script = "${path.module}/scripts/setup.sh"
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
    google_compute_firewall.baffles_k3s_firewall,
  ]
}
