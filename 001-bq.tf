
resource "google_project_service" "dts" {
  project = var.target_project
  service                    = "bigquerydatatransfer.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Service Account
resource "google_service_account" "bigquery_scheduled_queries" {
  account_id   = "bigquery-scheduled-queries"
  display_name = "BigQuery Scheduled Queries Service Account"
  description  = "Used to run BigQuery Data Transfer jobs."
  project = var.target_project
}

# Wait for the new Services and Service Accounts settings to propagate
resource "time_sleep" "wait_for_settings_propagation" {
  # It can take a while for the enabled services
  # and service accounts to propagate. Experiment
  # with this value until you find a time that is
  # consistently working for all the deployments.
  create_duration = "60s"

  depends_on = [
    google_project_service.dts,
    google_service_account.bigquery_scheduled_queries
  ]
}

resource "google_project_iam_member" "bigquery_scheduler_permissions" {
  project = var.target_project
  role   = "roles/iam.serviceAccountShortTermTokenMinter"
  # member = "serviceAccount:service-${var.target_project}@gcp-sa-bigquerydatatransfer.iam.gserviceaccount.com"
  member = "serviceAccount:bigquery-scheduled-queries@barry-project1-1586534486365.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_for_settings_propagation]
}

resource "google_project_iam_binding" "bigquery_datatransfer_admin" {
  project = var.target_project
  role    = "roles/bigquery.admin"
  members = ["serviceAccount:${google_service_account.bigquery_scheduled_queries.email}"]

  depends_on = [time_sleep.wait_for_settings_propagation]
}


resource "google_bigquery_dataset" "my_dataset" {
  depends_on = [google_project_iam_member.bigquery_scheduler_permissions]

  dataset_id    = "my_dataset"
  friendly_name = "foo"
  description   = "bar"
  location      = var.region
  project = var.target_project
}

resource "google_bigquery_data_transfer_config" "query_config" {

  service_account_name = "bigquery-scheduled-queries@barry-project1-1586534486365.iam.gserviceaccount.com"
  depends_on = [google_project_iam_member.bigquery_scheduler_permissions]
  project = var.target_project
  display_name           = "my-query"
  location               = var.region
  data_source_id         = "scheduled_query"
  schedule       = "every 15 minutes"
  destination_dataset_id = google_bigquery_dataset.my_dataset.dataset_id
  params = {
    destination_table_name_template = "my_table"
    write_disposition               = "WRITE_APPEND"
    query                           = "SELECT name FROM tabl WHERE x = 'y'"
  }
}
