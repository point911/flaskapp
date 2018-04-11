resource "google_sql_database_instance" "ableto-db" {
  name = "ableto-db-i"
  database_version = "MYSQL_5_7"
  region      = "${var.gce_region_1}"

  settings {
    tier = "db-f1-micro"
  }
}


resource "google_sql_database" "abletodb" {
  name      = "abletodb"
  instance  = "${google_sql_database_instance.ableto-db.name}"
  charset   = "latin1"
}


resource "google_sql_user" "users" {
  name     = "ableto"
  instance = "${google_sql_database_instance.ableto-db.name}"
  password = "changeme"
}