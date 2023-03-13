variable "bastion_user" {
  description = "username for bastion"
}

variable "bastion_ssh_location" {
  description = "Location of the public SSH key to add to bastion"
}


# // Dedicated service account for the Bastion instance.
resource "google_service_account" "bastion" {
  account_id   = "bastion-account"
  display_name = "GKE Bastion Service Account"
}

// Allow access to the Bastion Host via SSH.
resource "google_compute_firewall" "bastion-ssh" {
  name          = "bastion-ssh"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  project       = var.project_id
  source_ranges = ["0.0.0.0/0"] // TODO: Restrict further.

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["bastion"]
}

// The Bastion host.
resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project_id
  tags         = ["bastion"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id


    access_config {
      // Not setting "nat_ip", use an ephemeral external IP.
      network_tier = "STANDARD"
    }
  }

  // Allow the instance to be stopped by Terraform when updating configuration.
  allow_stopping_for_update = true

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  metadata = {
    ssh-keys = "${var.bastion_user}:${file(var.bastion_ssh_location)}"
  }
}

output "bastion_ip" {
  value = "${google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip}"
}