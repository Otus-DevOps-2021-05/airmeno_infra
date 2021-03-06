variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable subnet_id {
  description = "Subnets for modules"
}
variable mongod_ip {
  description = "Mongodb IP"
}
variable private_key_path {
  description = "path to private key"
}
variable enable_provision {
  description = "Enable provisioner"
  default     = false
}
