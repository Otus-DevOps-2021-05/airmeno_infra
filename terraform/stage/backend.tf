terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "otus-meno"
    region     = "ru-central1-a"
    key        = "stage/terraform.tfstate"
    access_key = "db2ax9l6HC7XVJdRkqlr"
    secret_key = "4oxD88tdnqubvh0671XZE7iHjp8UmTIdngHstPfe"
    
    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
