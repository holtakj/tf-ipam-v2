terraform {
  required_version = ">= 1.8.0"
}

module "ipam" {
  source = "./.."

  base_cidr     = var.base_cidr
  min_prefix    = var.min_prefix
  max_prefix    = var.max_prefix
  reserved      = var.reserved
  suggest_count = var.suggest_count
}

output "subnet_count" {
  value     = module.ipam.subnet_count
  sensitive = true
}

output "next_free_cidrs" {
  value = module.ipam.next_free_cidrs
}

output "reserved" {
  value     = module.ipam.reserved
  sensitive = true
}

output "zzz_graph" {
  value = module.ipam.zzz_graph
}

# debug
# output "debug_braille" {
#   value = module.ipam.debug_braille
# }