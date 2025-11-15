terraform {
  backend "gcs" {
    bucket = "fifth-medley-478216-a7-backend"
    prefix = "terraform/state" # path inside bucket (keeps states organized)
  }
}
