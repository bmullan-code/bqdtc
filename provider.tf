# gcloud auth application-default login

# Retrieve an access token as the Terraform runner
terraform {
  backend "gcs" {
    bucket = "barry-mullan-db2-bucket"
    prefix = "google_bigquery_data_transfer_config"
  }
}

provider "google" {
  project = "barry-mullan"
  region  = "us-central1"
  zone    = "us-central1-c"
}

