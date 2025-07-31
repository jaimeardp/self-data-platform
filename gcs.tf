# -----------------------------------------------------------------------------
# gcs.tf
#
# This file defines the GCS buckets used in the project.
# NOTE: The Composer DAGs bucket is now created automatically by Composer itself.
# -----------------------------------------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Bucket for landing raw data files from source systems (e.g., CRM, billing).
resource "google_storage_bucket" "landing_bucket" {
  name                        = "${var.landing_bucket_name}-${random_id.bucket_suffix.hex}"
  location                    = var.gcp_region
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = "data-landing-zone"
    owner       = "self-data-platform"
  }
}


# NEW: Bucket for storing transformed Parquet files in the raw zone.
resource "google_storage_bucket" "raw_bucket" {
  name                        = "${var.raw_bucket_name}-${random_id.bucket_suffix.hex}"
  location                    = var.gcp_region
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = {
    environment = "data-raw-zone"
    owner       = "self-data-platform"
  }
}

# Bucket to store the Cloud Function's zipped source code.
resource "google_storage_bucket" "function_source_bucket" {
  name                        = "self-function-source-${random_id.bucket_suffix.hex}"
  location                    = var.gcp_region
  uniform_bucket_level_access = true
  labels = {
    purpose = "terraform-source-code"
  }
  # depends_on = [google_project_service.apis]
}