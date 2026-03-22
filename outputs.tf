output "subnet_count" {
  description = "Map of CIDR sizes to the number of subnets that can be carved from base_cidr (keys: /<min_prefix> through /<max_prefix>)."
  value       = local.subnet_count

  precondition {
    condition     = var.max_prefix >= var.min_prefix
    error_message = format("max_prefix /%d must be greater than or equal to min_prefix /%d.", var.max_prefix, var.min_prefix)
  }

  precondition {
    condition     = local.base_prefix_length <= var.max_prefix
    error_message = format("base_cidr /%d is narrower than max_prefix /%d. Provide a broader base_cidr or raise max_prefix.", local.base_prefix_length, var.max_prefix)
  }
}

output "next_free" {
  description = "Per-size next free suggestions keyed from /<min_prefix> to /<max_prefix>. Value is a list (possibly empty) of up to suggest_count objects with fields: cidr_base, size, cidr, reservable_subnet_count, alignment_skipped_ip_count."
  value       = local.next_free_cidr_suggestions_by_size
}

output "reserved" {
  description = "Map of all reservation names to CIDRs."
  value       = var.reserved

  precondition {
    condition     = local.reserved_cidrs_unique
    error_message = "Reservation CIDRs must be unique."
  }

  precondition {
    condition     = local.reserved_cidrs_exist
    error_message = "Every reservation CIDR must be canonical, aligned to the base network, within the base range, and within [min_prefix, max_prefix]."
  }

  precondition {
    condition     = local.reserved_cidrs_non_overlapping
    error_message = "Reserved CIDRs must not overlap."
  }
}
