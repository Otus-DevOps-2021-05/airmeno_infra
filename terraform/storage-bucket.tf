provider "yandex" {
  version                  = 0.35
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_storage_bucket" "otus-meno" {
  access_key = var.access_key
  secret_key = var.secret_key
  bucket     = var.bucket_name
  # force_destroy удалит баккет с контентом, без этой опции удалить можно только пустой баект
  force_destroy = "true"
}
