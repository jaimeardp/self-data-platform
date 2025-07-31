# -----------------------------------------------------------------------------
# iam.tf
#
# This file defines the dedicated service accounts managed by the platform
# and the permissions for platform-level services like Composer.
# -----------------------------------------------------------------------------

# --- Service Account Definitions ---
data "google_project" "project" {
  project_id = var.gcp_project_id
}

# Service Account for the Composer Environment
resource "google_service_account" "composer_sa" {
  account_id   = "${var.composer_environment_name}-sa"
  display_name = "Service Account for Self Composer Environment"
  project      = var.gcp_project_id
}

# Service Account for the GCS Transformer Cloud Function (Identity only)
resource "google_service_account" "gcs_transformer_function_sa" {
  account_id   = "self-gcs-transformer-sa"
  display_name = "SA for GCS Transformer Function"
  project      = var.gcp_project_id
}


# --- IAM Bindings for Composer ---

# Grant the Composer Service Agent the "Composer Worker" role on its own SA.
resource "google_project_iam_member" "composer_agent_is_worker" {
  project = var.gcp_project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [google_service_account.composer_sa]
}

resource "google_storage_bucket_iam_member" "composer_sa_can_read_landing_bucket" {
  bucket = google_storage_bucket.landing_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_storage_bucket.landing_bucket,
    google_service_account.composer_sa,
  ]
}

# Grant the Composer SA permissions to read from the raw parquet bucket
resource "google_storage_bucket_iam_member" "composer_sa_can_read_raw_bucket" {
  bucket = google_storage_bucket.raw_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_storage_bucket.raw_bucket,
    google_service_account.composer_sa,
  ]
}

# Grant the Composer SA permissions on the processed BigQuery dataset
resource "google_bigquery_dataset_iam_member" "composer_sa_can_manage_raw_dataset" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.raw_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_bigquery_dataset.raw_dataset,
    google_service_account.composer_sa,
  ]
}

# Grant the Composer SA permissions on the processed BigQuery dataset
resource "google_bigquery_dataset_iam_member" "composer_sa_can_manage_curated_dataset" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.curated_dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_bigquery_dataset.curated_dataset,
    google_service_account.composer_sa,
  ]
}


# --- IAM Bindings for Platform Services ---
# Grant the default Cloud Build SA permission to read from source repositories.
resource "google_project_iam_member" "cloudbuild_source_reader" {
  project = var.gcp_project_id
  role    = "roles/source.reader"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# FIXED: Grant the GCS Service Agent the Pub/Sub Publisher role.
# This is required for GCS to be able to publish events for Eventarc triggers.
resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.gcp_project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
  # depends_on = [google_project_service.apis]
}

resource "google_project_iam_member" "composer_sa_bigquery_job_user" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_service_account.composer_sa
  ]
}

# ─── Grant READ access on the STAGING dataset ───────────────────────────
resource "google_bigquery_dataset_iam_member" "composer_sa_data_viewer_staging" {
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.staging_dataset.dataset_id  # "self_staging_zone"
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.composer_sa.email}"

  depends_on = [
    google_service_account.composer_sa
  ]
}
