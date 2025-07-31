# -----------------------------------------------------------------------------
# variables.tf
#
# This file declares all the variables used in the configuration.
# -----------------------------------------------------------------------------

variable "gcp_bucket_tf_state" {
  type        = string
  description = "The GCP bucket for storing Terraform state files."
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID where the resources will be created."
}

variable "gcp_region" {
  type        = string
  description = "The GCP region for the resources."
  default     = "us-central1"
}

variable "platform_name" {
  type        = string
  description = "The base name for shared platform resources like the VPC."
  default     = "self-data-platform"
}

variable "composer_environment_name" {
  type        = string
  description = "The name for the Cloud Composer environment."
  # FIXED: Shortened the name to be under 30 characters for the service account ID.
  default = "self-cust-analytics-comp"
}

variable "landing_bucket_name" {
  type        = string
  description = "The base name for the GCS landing bucket."
  default     = "self-crm-landing-zone"
}

variable "bigquery_raw_dataset_id" {
  type        = string
  description = "The ID for the BigQuery raw dataset."
  default     = "self_raw_zone"
}

variable "bigquery_staging_dataset_id" {
  type        = string
  description = "The ID for the BigQuery staging dataset."
  default     = "self_staging_zone"
}

variable "bigquery_curated_dataset_id" {
  type        = string
  description = "The ID for the BigQuery curated dataset."
  default     = "self_curated_zone"
}

# NEW: Variable for the raw parquet bucket name
variable "raw_bucket_name" {
  type        = string
  description = "The base name for the GCS raw zone bucket (for Parquet files)."
  default     = "self-crm-raw-zone"
}


# NEW: Variable for the GitHub repository name (e.g., "my-org/my-repo")
variable "github_repository_name" {
  type        = string
  description = "The name of the GitHub repository in the format 'owner/repo'."
}

variable "github_repository_dags_name" {
  type        = string
  description = "The name of the GitHub repository for Airflow DAGs in the format 'owner/repo'."
}