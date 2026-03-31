variable "tenant_name"  { type = string }
variable "env_name"     { type = string }
variable "project_code" { type = string }
variable "os_image"     { type = string }

variable "vms" {
  description = "Map of VMs to provision with their specific flavors"
  type = map(object({
    flavor = string
    tags   = map(string)
  }))
}

variable "flavor_map" {
  type = map(object({
    cpu  = number
    ram  = string
    disk = string
  }))
  default = {
    "bronze" = { cpu = 1, ram = "1G", disk = "10G" }
    "silver" = { cpu = 2, ram = "2G", disk = "20G" }
    "gold"   = { cpu = 4, ram = "4G", disk = "50G" }
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for node access"
  type        = string
  sensitive   = true
  default = "none"
}
