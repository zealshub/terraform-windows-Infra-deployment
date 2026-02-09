terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ---------------- Provider ----------------
provider "google" {
  project     = "kasm-485616"
  region      = "us-central1"
  zone        = "us-central1-a"
  credentials = "key.json"
}

# ---------------- Variables ----------------
variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "vm_name" {
  type    = string
  default = "windows-server-01"
}

variable "machine_type" {
  type    = string
  default = "n2-standard-4"
}

variable "windows_admin_password" {
  type      = string
  sensitive = true
}

# ---------------- Existing Default Network ----------------
data "google_compute_network" "default" {
  name = "default"
}

data "google_compute_subnetwork" "default" {
  name   = "default"
  region = var.region
}

# ---------------- Firewall: Allow RDP ----------------
resource "google_compute_firewall" "allow_rdp" {
  name    = "allow-rdp-windows"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["rdp"]
}

# ---------------- Static Public IP ----------------
resource "google_compute_address" "public_ip" {
  name   = "windows-public-ip"
  region = var.region
}

# ---------------- Windows VM ----------------
resource "google_compute_instance" "windows" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["rdp"]

  boot_disk {
    initialize_params {
      image = "projects/windows-cloud/global/images/family/windows-2022"
      size  = 60
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.default.self_link

    access_config {
      nat_ip = google_compute_address.public_ip.address
    }
  }

  metadata = {
    windows-startup-script-ps1 = <<-EOT
    net user ksam "${var.windows_admin_password}" /add
    net localgroup administrators ksam /add
    EOT
  }
}

# ---------------- Output ----------------
output "windows_public_ip" {
  value = google_compute_address.public_ip.address
}
