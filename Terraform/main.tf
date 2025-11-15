provider "google" {
  project = var.project
  # region  = var.region
  # zone    = var.zone
}

# resource "google_compute_network" "vpc" {
#   name                    = "swarm-vpc"
#   auto_create_subnetworks = false
# }
# resource "google_compute_subnetwork" "subnet" {
#   name          = "swarm-subnet"
#   ip_cidr_range = "10.0.0.0/16"
#   region        = var.region
#   network       = google_compute_network.vpc.name
# }

# resource "google_compute_firewall" "allow_http_ssh" {
#   name    = "allow-http-ssh"
#   network = google_compute_network.vpc.name
#   allow {
#     protocol = "tcp"
#     ports    = ["22", "80", "8080", "2377", "7946", "4789"]
#   }
#   source_ranges = ["0.0.0.0/0"]
# }

# SSH Key Generation
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private and public keys to local files
resource "local_file" "ansible" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa"
}


# Save the public key to a local file
resource "local_file" "ssh_pub_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/id_rsa.pub"
}

# Manager instance
resource "google_compute_instance" "manager" {
  name         = "swarm-manager"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["swarm-node"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    network    = "default"
    # subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${tls_private_key.ssh_key.public_key_openssh}"
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")
}

# Two workers
resource "google_compute_instance" "worker" {
  count        = 2
  name         = "swarm-worker-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["swarm-node"]
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    network    = "default"
    # subnetwork = google_compute_subnetwork.subnet.name
    access_config {}
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${tls_private_key.ssh_key.public_key_openssh}"
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
}



# Load Balance static ip
resource "google_compute_address" "lb_ip" {
  name   = "swarm-lb-ip"
  region = var.region
}

# Health check
resource "google_compute_http_health_check" "swarm_hc" {
  name         = "swarm-hc"
  request_path = "/"
  port         = 8080
}

# Target Pool and Forwarding Rule
resource "google_compute_target_pool" "swarm_pool" {
  name   = "swarm-target-pool"
  region = var.region
  instances = concat(
    [google_compute_instance.manager.self_link],
    [for w in google_compute_instance.worker : w.self_link]
  )
  health_checks = [google_compute_http_health_check.swarm_hc.self_link]
}


resource "google_compute_forwarding_rule" "swarm_forward" {
  name        = "swarm-forward-rule"
  ip_address  = google_compute_address.lb_ip.address
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_pool.swarm_pool.self_link
  region      = var.region
}





