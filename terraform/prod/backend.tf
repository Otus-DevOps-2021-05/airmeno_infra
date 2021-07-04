terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "otus-meno"
    region     = "ru-central1-a"
    key        = "prod/terraform.tfstate"
    access_key = "key_id"
    secret_key = "secret"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
