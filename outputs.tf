output "subnet_count_by_cidr_size" {
  description = "Map of CIDR sizes to the number of subnets that can be carved from base_network_cidr (keys: /<min_prefix_length> through /<max_prefix_length>)."
  value       = local.subnet_count_by_cidr_size

  precondition {
    condition     = var.max_prefix_length >= var.min_prefix_length
    error_message = format("max_prefix_length /%d must be greater than or equal to min_prefix_length /%d.", var.max_prefix_length, var.min_prefix_length)
  }

  precondition {
    condition     = local.base_prefix_length >= var.min_prefix_length
    error_message = format("base_network_cidr /%d is broader than min_prefix_length /%d. Provide a narrower base_network_cidr or lower min_prefix_length.", local.base_prefix_length, var.min_prefix_length)
  }

  precondition {
    condition     = local.base_prefix_length <= var.max_prefix_length
    error_message = format("base_network_cidr /%d is narrower than max_prefix_length /%d. Provide a broader base_network_cidr or raise max_prefix_length.", local.base_prefix_length, var.max_prefix_length)
  }
}

output "free_cidr_suggestions" {
  description = "Per-size next free suggestion keyed from /<min_prefix_length> to /<max_prefix_length>. Value is null when no subnet can be reserved; otherwise an object with fields: cidr_base, size, cidr, reservable_subnet_count, alignment_skipped_ip_count."
  value       = local.next_free_cidr_suggestions_by_size
}

output "reserved" {
  description = "Map of all reservation names to CIDRs."
  value       = var.reservations

  precondition {
    condition     = local.reserved_cidrs_unique
    error_message = "Reservation CIDRs must be unique."
  }

  precondition {
    condition     = local.reserved_cidrs_exist
    error_message = "Every reservation CIDR must be canonical, aligned to the base network, within the base range, and within [min_prefix_length, max_prefix_length]."
  }

  precondition {
    condition     = local.reserved_cidrs_non_overlapping
    error_message = "Reserved CIDRs must not overlap."
  }
}
