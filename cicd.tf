# -----------------------------------------------------------------------------
# cicd.tf
#
# NEW FILE: This file defines all the resources needed for Workload Identity
# Federation with GitHub Actions.
# -----------------------------------------------------------------------------

locals {
  # Define the roles for the CI/CD service account. This set of roles is
  # comprehensive for deploying Cloud Functions and related resources.
  cicd_roles = [
    # Core permissions for deploying functions and their triggers
    "roles/cloudfunctions.developer",
    "roles/cloudbuild.builds.editor",
    "roles/run.admin", # Cloud Functions v2 run on Cloud Run
    "roles/eventarc.admin",

    # Permission to act as other service accounts (e.g., the function's runtime SA)
    "roles/iam.serviceAccountUser",

    # Permissions for storing artifacts and state
    "roles/storage.objectAdmin",      # To manage Terraform state & build artifacts
    "roles/artifactregistry.writer", # To store function container images

    # Broad permission to manage IAM policies for other resources.
    # For production, consider a custom role with only the necessary iam.* permissions.
    "roles/resourcemanager.projectIamAdmin",
  ]
}

# Service Account for the CI/CD pipeline (GitHub Actions)
resource "google_service_account" "github_actions_sa" {
  project      = var.gcp_project_id
  account_id   = "github-actions-cicd"
  display_name = "GitHub Actions CI/CD"
  description  = "Service Account for Workload Identity used by GitHub Actions"
}

# Grant the necessary roles to the CI/CD service account
resource "google_project_iam_member" "cicd_roles" {
  project  = var.gcp_project_id
  for_each = toset(local.cicd_roles)
  role     = each.value
  member   = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# NEW: Create a custom role with only the permissions needed to manage bucket IAM policies.
resource "google_project_iam_custom_role" "bucket_iam_manager" {
  project     = var.gcp_project_id
  role_id     = "bucketIamManager"
  title       = "Bucket IAM Manager"
  description = "Allows setting and getting IAM policies on GCS buckets"
  permissions = [
    "storage.buckets.getIamPolicy",
    "storage.buckets.setIamPolicy",
  ]
}

# NEW: Assign the custom role to the CI/CD service account.
resource "google_project_iam_member" "cicd_custom_bucket_iam" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.bucket_iam_manager.id
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Workload Identity Pool for GitHub
resource "google_iam_workload_identity_pool" "github_pool" {
  provider                  = google-beta
  project                   = var.gcp_project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
  description               = "Workload Identity Pool for GitHub Actions"
}

# Workload Identity Pool Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  provider                           = google-beta
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC provider for GitHub Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
    "attribute.refs"       = "assertion.ref"

  }
  # attribute_condition = "attribute.repository == \"${var.github_repository_name}\""
    attribute_condition = "attribute.repository in [\"${var.github_repository_name}\", \"${var.github_repository_dags_name}\"]"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Link the GitHub repository to the CI/CD service account
resource "google_service_account_iam_member" "github_actions_workload_user" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repository_name}"
}

# Link the GitHub repository to the CI/CD service account
resource "google_service_account_iam_member" "github_actions_workload_user_dags" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repository_dags_name}"
}