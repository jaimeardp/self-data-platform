# -----------------------------------------------------------------------------
# bigquery.tf
#
# This file defines the BigQuery datasets for the data platform layers.
# -----------------------------------------------------------------------------

resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id    = var.bigquery_raw_dataset_id
  friendly_name = "Self Raw Zone"
  description   = "Dataset for raw, unprocessed data ingested from source systems."
  location      = var.gcp_region

  labels = {
    environment = "data-raw-zone"
    owner       = "self-data-platform"
  }
}


###############################################################################
# 2. RAW TABLE  –  Hourly partition, clustering, labels & expiration
###############################################################################
resource "google_bigquery_table" "customer_events_raw" {
  project    = var.gcp_project_id
  dataset_id = var.bigquery_raw_dataset_id
  table_id   = "customer_events_raw"
  # location   = var.gcp_region
  description = "Raw, merged customer events (deduplicated on event_uuid)"

  # ------------ schema definition ------------
  schema = jsonencode([
    { name = "id_cliente",               type = "STRING",  mode = "REQUIRED" },
    { name = "numero_telefono",          type = "INT64",   mode = "NULLABLE" },
    { name = "nombre_cliente",           type = "STRING",  mode = "NULLABLE" },
    { name = "direccion",                type = "STRING",  mode = "NULLABLE" },
    { name = "tipo_plan",                type = "STRING",  mode = "NULLABLE" },
    { name = "consumo_datos_gb",         type = "FLOAT64", mode = "NULLABLE" },
    { name = "estado_cuenta",            type = "STRING",  mode = "NULLABLE" },
    { name = "fecha_registro",           type = "DATE",    mode = "NULLABLE" },
    { name = "fecha_evento",             type = "DATETIME",mode = "NULLABLE" },
    { name = "tipo_evento",              type = "STRING",  mode = "NULLABLE" },
    { name = "id_dispositivo",           type = "INT64",   mode = "NULLABLE" },
    { name = "marca_dispositivo",        type = "STRING",  mode = "NULLABLE" },
    { name = "antiguedad_cliente_meses", type = "INT64",   mode = "NULLABLE" },
    { name = "score_crediticio",         type = "INT64",   mode = "NULLABLE" },
    { name = "origen_captacion",         type = "STRING",  mode = "NULLABLE" },
    { name = "ingestion_ts",             type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "event_uuid",               type = "STRING",  mode = "REQUIRED" },
    { name = "source_file",              type = "STRING",  mode = "NULLABLE" }
  ])

  # ------------ partitioning & clustering ------------
  time_partitioning {
    type                     = "HOUR"
    field                    = "ingestion_ts"
    # expiration_ms            = 730 * 24 * 60 * 60 * 1000   # 730 days
  }

  require_partition_filter = true


  clustering = ["id_cliente", "tipo_evento"]   # attribute, not block

  labels = {
    layer   = "raw"
    domain  = "crm"
  }
}

resource "google_bigquery_dataset" "staging_dataset" {
  dataset_id    = var.bigquery_staging_dataset_id
  friendly_name = "Self Staging Zone"
  description   = "Dataset for staging data before processing."
  location      = var.gcp_region

  labels = {
    environment = "data-staging-zone"
    owner       = "self-data-platform"
  }
}

###############################################################################
# External table: every column defined as STRING
# Dataset  : self_staging_zone
# Table ID : customer_events_ext
###############################################################################
resource "google_bigquery_table" "customer_events_ext" {
  project    = var.gcp_project_id            # e.g. "oceanic-student-465214-j2"
  dataset_id = "${google_bigquery_dataset.staging_dataset.dataset_id}"
  table_id   = "customer_events_ext"
  # location   = var.gcp_region              # e.g. "us-central1"

  description = "External Parquet feed – all columns stored as STRING"

  # ── FULL SCHEMA  ──────────────────────────────────────────────────────────
  schema = jsonencode([
    # business columns
    { name = "id_cliente",               type = "STRING",  mode = "REQUIRED" },
    { name = "numero_telefono",          type = "INT64",   mode = "NULLABLE" },
    { name = "nombre_cliente",           type = "STRING",  mode = "NULLABLE" },
    { name = "direccion",                type = "STRING",  mode = "NULLABLE" },
    { name = "tipo_plan",                type = "STRING",  mode = "NULLABLE" },
    { name = "consumo_datos_gb",         type = "FLOAT64", mode = "NULLABLE" },
    { name = "estado_cuenta",            type = "STRING",  mode = "NULLABLE" },
    { name = "fecha_registro",           type = "STRING",    mode = "NULLABLE" },
    { name = "fecha_evento",             type = "STRING",mode = "NULLABLE" },
    { name = "tipo_evento",              type = "STRING",  mode = "NULLABLE" },
    { name = "id_dispositivo",           type = "INT64",   mode = "NULLABLE" },
    { name = "marca_dispositivo",        type = "STRING",  mode = "NULLABLE" },
    { name = "antiguedad_cliente_meses", type = "INT64",   mode = "NULLABLE" },
    { name = "score_crediticio",         type = "INT64",   mode = "NULLABLE" },
    { name = "origen_captacion",         type = "STRING",  mode = "NULLABLE" },
    { name = "ingestion_ts",             type = "STRING", mode = "REQUIRED" },
    { name = "event_uuid",               type = "STRING",  mode = "REQUIRED" },
    { name = "source_file",              type = "STRING",  mode = "NULLABLE" },

    # Hive‑style partition columns
    { name = "year",  type = "STRING", mode = "NULLABLE" },
    { name = "month", type = "STRING", mode = "NULLABLE" },
    { name = "day",   type = "STRING", mode = "NULLABLE" },
    { name = "hour",  type = "STRING", mode = "NULLABLE" }
  ])

  # ── EXTERNAL DATA CONFIG ─────────────────────────────────────────────────
  external_data_configuration {
    source_format = "PARQUET"
    autodetect    = false                       # use the explicit schema above

    # single wildcard – BigQuery recurses through year=/month=/day=/hour=/
    source_uris = [
      "gs://${google_storage_bucket.raw_bucket.name}/*.parquet"
    ]

    hive_partitioning_options {
      mode                     = "STRINGS"         # infer year/month/day/hour cols
      source_uri_prefix        = "gs://${google_storage_bucket.raw_bucket.name}/"
      require_partition_filter = true           # safety for ad‑hoc queries
    }
  }

  labels = {
    layer  = "staging"
    schema = "all_string"
  }
}

resource "google_bigquery_dataset" "curated_dataset" {
  dataset_id    = var.bigquery_curated_dataset_id
  friendly_name = "Self Curated Zone"
  description   = "Dataset for curated, processed data ready for analysis."
  location      = var.gcp_region

  labels = {
    environment = "data-curated-zone"
    owner       = "self-data-platform"
  }
}