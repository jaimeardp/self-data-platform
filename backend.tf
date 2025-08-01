# -----------------------------------------------------------------------------
# backend.tf
#
# Defines the remote backend for the PLATFORM state.
# -----------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = "self-tfstate-bkt" # Using the bucket you created
    prefix = "platform/infra"
  }
}