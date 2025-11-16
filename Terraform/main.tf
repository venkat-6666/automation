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
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
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
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
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





# Static IP for Load Balancer
resource "google_compute_address" "swarm_lb_ip" {
  name   = "swarm-lb-ip"
  region = var.region
}

# Health Check for Swarm Nodes



# Instance Group for Swarm Nodes
resource "google_compute_instance_group" "swarm_group" {
  name = "swarm-group"
  zone = var.zone

  instances = concat(
    [google_compute_instance.manager.self_link],
    [for w in google_compute_instance.worker : w.self_link]
  )

  named_port {
    name = "http"
    port = 8000
  }
}

resource "google_compute_health_check" "swarm_hc" {
  name               = "swarm-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 8000
  }
}


# Backend Service for Load Balancer
resource "google_compute_backend_service" "swarm_backend" {
  name                  = "swarm-backend"
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  port_name             = "http"

  health_checks = [
    google_compute_health_check.swarm_hc.self_link
  ]

 backend {
  group                         = google_compute_instance_group.swarm_group.self_link
  balancing_mode                = "CONNECTION"
  max_connections_per_instance  = 1000
}



# Forwarding Rule for Load Balancer Frontend Port 80
resource "google_compute_forwarding_rule" "swarm_fr" {
  name                  = "swarm-forwarding-rule"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "80"

  ip_address      = google_compute_address.swarm_lb_ip.address
  backend_service = google_compute_backend_service.swarm_backend.self_link
}




