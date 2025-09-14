terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.9.0"  # specify the version you need
    }
  }

  required_version = ">= 1.5.0"  # optional, specify your Terraform version
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

resource "databricks_cluster" "example" {
  cluster_name            = "example-cluster"
  spark_version           = "16.4.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 30
  num_workers             = 2
}

resource "databricks_secret_scope" "example_scope" {
  name = "taxi-scope"
  initial_manage_principal = "users" # who can manage secrets in this scope
}


resource "databricks_secret" "example_secret" {
  key          = "key"
  string_value = var.example_secret_value
  scope        = databricks_secret_scope.example_scope.name
}

resource "databricks_notebook" "iactest" {
  path     = "/Workspace/Users/${var.databricks_user}/TestscriptIAC"
  language = "PYTHON"
  source   = "../Code/iac.py"
}

resource "databricks_job" "example_job" {
  name = "example-notebook-job"

  # Use the existing cluster
  existing_cluster_id = databricks_cluster.example.id

  # Define the notebook task
  notebook_task {
    notebook_path = databricks_notebook.iactest.path
  }

  # Optional: schedule the job (example: run daily at midnight UTC)
  schedule {
    quartz_cron_expression = "0 0 0 * * ?"  # every day at midnight
    timezone_id            = "UTC"
  }

  max_concurrent_runs = 1
}