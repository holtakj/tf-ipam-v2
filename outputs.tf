output "subnet_count" {
  description = "Map of CIDR sizes to the number of subnets that can be carved from base_cidr (keys: /<min_prefix> through /<max_prefix>)."
  value       = local.subnet_count
  sensitive   = true

  precondition {
    condition     = local.base_cidr_subnets_enabled
    error_message = "base_cidr must be in a subnets-enabled category. Allowed categories are private_use and carrier_grade_nat."
  }

  precondition {
    condition     = var.max_prefix >= var.min_prefix
    error_message = format("max_prefix /%d must be greater than or equal to min_prefix /%d.", var.max_prefix, var.min_prefix)
  }

  precondition {
    condition     = local.base_prefix_length <= var.max_prefix
    error_message = format("base_cidr /%d is narrower than max_prefix /%d. Provide a broader base_cidr or raise max_prefix.", local.base_prefix_length, var.max_prefix)
  }
}

output "next_free_cidrs" {
  description = "Per-size next free suggestions keyed from /<min_prefix> to /<max_prefix>. Value is a list (possibly empty) of up to suggest_count objects with fields: cidr_base, cidr_size, cidr, cidr_ip_count, reservable_subnet_count, alignment_skipped_ip_count."
  value       = local.next_free_cidr_suggestions_by_size
}

output "reserved" {
  description = "Map of all reservation names to their values (canonical IPv4 CIDR or IP range)."
  value       = var.reserved
  sensitive   = true

  precondition {
    condition     = local.reserved_cidrs_unique
    error_message = "Reservation values must be unique."
  }

  precondition {
    condition     = local.reserved_cidrs_exist
    error_message = "Every reservation CIDR must be canonical, aligned to the base network, within the base range, and within [min_prefix, max_prefix]."
  }

  precondition {
    condition     = local.reserved_ip_ranges_valid
    error_message = "Every IP range reservation must have start address ≤ end address and the entire range must fall within the base CIDR window."
  }

  precondition {
    condition     = local.reserved_cidrs_non_overlapping
    error_message = "Reserved CIDRs must not overlap."
  }
}

output "zzz_graph" {
  description = "Terminal-friendly reservation heat-map and bucket detail. Intentionally named to print last in Terraform output listings."
  value = {
    base_cidr       = var.base_cidr
    bucket_count    = local.reservation_heatmap_bucket_count
    bucket_size_ips = local.reservation_heatmap_bucket_size
    legend          = "░=0%, ▒=1-50%, ▓=51-99%, █=100%"
    heatmap         = local.reservation_heatmap_strip
  }
}
