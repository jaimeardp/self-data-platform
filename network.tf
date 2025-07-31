# -----------------------------------------------------------------------------
# network.tf
#
# This file defines all the networking resources for the data platform.
# -----------------------------------------------------------------------------

# Best Practice: Create a dedicated VPC for your data platform resources.
resource "google_compute_network" "data_platform_vpc" {
  name                    = "${var.platform_name}-vpc"
  auto_create_subnetworks = false # We will create a custom subnetwork
}

resource "google_compute_subnetwork" "data_platform_subnet" {
  name          = "${var.platform_name}-subnet"
  ip_cidr_range = "10.2.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.data_platform_vpc.id
}