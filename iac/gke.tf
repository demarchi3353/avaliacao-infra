provider "google" {
  project     = "teste-softdesign"
  region      = "us-central1"
}

resource "google_container_cluster" "standard_cluster" {
  name     = "cl-teste-softdesign"
  location = "us-central1-a"

  remove_default_node_pool = true
  initial_node_count       = 1
  
}

resource "google_container_node_pool" "primary_pool" {
  name       = "pool-teste-softdesign"
  location   = "us-central1-a"
  cluster    = google_container_cluster.standard_cluster.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    disk_size_gb = 10
    disk_type    = "pd-standard"
  }
}