output "manager_ip" {
  value = google_compute_instance.manager.network_interface[0].access_config[0].nat_ip
}

output "worker_ips" {
  value = [
    for w in google_compute_instance.worker :
    w.network_interface[0].access_config[0].nat_ip
  ]
}
