# -----------------------------------------------------------------------------
# composer.tf
#
# This file defines the Cloud Composer environment itself.
# -----------------------------------------------------------------------------

resource "google_composer_environment" "composer_env" {
  name   = var.composer_environment_name
  region = var.gcp_region

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    software_config {
      image_version = "composer-3-airflow-2.10.5"
    }

    # Best Practice: Use the dedicated network and service account.
    node_config {
      network         = google_compute_network.data_platform_vpc.id
      subnetwork      = google_compute_subnetwork.data_platform_subnet.id
      service_account = google_service_account.composer_sa.name
    }
    # NOTE: dag_gcs_prefix is no longer set here. Composer 2 creates the bucket automatically.
  }

  labels = {
    environment = "orchestration"
    owner       = "self-data-platform"
  }

  depends_on = [
    # Explicitly depend on all relevant IAM bindings to ensure they are created first.
    google_storage_bucket_iam_member.composer_sa_can_read_landing_bucket,
    google_storage_bucket_iam_member.composer_sa_can_read_raw_bucket,
    google_bigquery_dataset_iam_member.composer_sa_can_manage_raw_dataset,
  ]
}