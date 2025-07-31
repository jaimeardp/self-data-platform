# -----------------------------------------------------------------------------
# outputs.tf
#
# This file defines outputs that will be displayed after a successful `terraform apply`.
# -----------------------------------------------------------------------------

output "composer_environment_name" {
  description = "The name of the created Cloud Composer environment."
  value       = google_composer_environment.composer_env.name
}

output "composer_dags_gcs_prefix" {
  description = "The GCS path to the DAGs folder, created automatically by Composer."
  value       = google_composer_environment.composer_env.config[0].dag_gcs_prefix
}

output "landing_bucket_name" {
  description = "The name of the GCS bucket created for landing data."
  value       = google_storage_bucket.landing_bucket.name
}

output "raw_bucket_name" {
  description = "The name of the GCS bucket created for raw data."
  value       = google_storage_bucket.raw_bucket.name
}

output "bigquery_raw_dataset_id" {
  description = "The ID of the BigQuery raw dataset."
  value       = google_bigquery_dataset.raw_dataset.dataset_id
}

output "composer_service_account_email" {
  description = "The email of the dedicated service account created for Composer."
  value       = google_service_account.composer_sa.email
}

output "data_platform_network_name" {
  description = "The name of the VPC network created for the data platform."
  value       = google_compute_network.data_platform_vpc.name
}

output "data_platform_service_account_email_transformer_function" {
  description = "The email of the service account created for the GCS Transformer Function."
  value       = google_service_account.gcs_transformer_function_sa.email
}


output "data_plataform_bucket_name_for_function_source" {
  description = "The name of the GCS bucket where the function source code is stored."
  value       = google_storage_bucket.function_source_bucket.name
  
}