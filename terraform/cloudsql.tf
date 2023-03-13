variable "sql_user" {
  description = "sql_user"
}

variable "sql_pass" {
  description = "pass"
}

variable "sql_root_pass" {
  description = "Root password"
}

variable "sql_db_name" {
  description = "Name of the database"
}



resource "google_sql_database_instance" "master" {
#  name             = "sql-${terraform.workspace}-master"
  name             = "demo-db"
  region           = "${var.region}"
  database_version = "POSTGRES_14"
  root_password = "${var.sql_root_pass}"
  deletion_protection = false

  settings {
    availability_type = "ZONAL"
    tier              = "db-f1-micro"
    disk_autoresize   = true

    ip_configuration {
      authorized_networks {
        value = "0.0.0.0/0"
      }

      require_ssl  = false
      ipv4_enabled = true
    }
  }
}

resource "google_sql_user" "user" {
  depends_on = [
    google_sql_database_instance.master,
  ]

  instance = "${google_sql_database_instance.master.name}"
  name     = "${var.sql_user}"
  password = "${var.sql_pass}"
}

resource "google_sql_database" "database" {
  name     = "${var.sql_db_name}"
  instance = google_sql_database_instance.master.name
}

provider "postgresql" {
  scheme    = "gcppostgres"
  host      = "${google_sql_database_instance.master.connection_name}"         # The CloudSQL Instance
  port      = 5432
  username  = "postgres"           # Username from Vault
  password  = "${var.sql_root_pass}"             # Password from Vault
  superuser = true
  sslmode   = "disable"
}

resource "postgresql_grant" "demo_role" {
  database    = "${var.sql_db_name}"
  role        = "${var.sql_user}"
  schema      = "public"
  object_type = "database"
  #privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES", "TRIGGER", "CREATE", "CONNECT", "TEMPORARY", "EXECUTE", "USAGE"]
  privileges  = [ "CREATE", "CONNECT", "TEMPORARY"]
  #privileges  = ["ALL"]

  depends_on = [
    google_sql_database.database,
    google_sql_user.user,
  ]
}