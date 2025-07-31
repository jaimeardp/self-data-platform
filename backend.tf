# -----------------------------------------------------------------------------
# backend.tf
#
# Defines the remote backend for the PLATFORM state.
# -----------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = var.gcp_bucket_tf_state # Using the bucket you created
    prefix = "platform/infra"
  }
}