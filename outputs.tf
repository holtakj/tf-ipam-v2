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
    base_cidr      = var.base_cidr
    total_ip_count = local.reservation_heatmap_total_ips
    ips_per_dot    = local.reservation_heatmap_bucket_size
    usage_percent  = local.reservation_heatmap_usage_percent
    legend         = "Dots represent reserved IPs, ordered bottom-to-top and left-to-right. If ips_per_dot > 1, each dot represents up to that many IPs."
    heatmap        = local.reservation_heatmap_strip
  }
}

locals {
  network_report_markdown = join("\n", concat([
    "# TF-IPAM Network report",
    "",
    format("- **Base CIDR:** `%s`", var.base_cidr),
    format("- **Prefix range:** `/%d` to `/%d`", var.min_prefix, var.max_prefix),
    format("- **Reservations:** %d", length(local.sorted_blocking_ranges)),
    "",
    "## Capacity",
    "",
    "| Total IPs | Reserved IPs | Available IPs | Utilization |",
    "| ---: | ---: | ---: | ---: |",
    format(
      "| %d | %d | %d | %.5f%% |",
      local.reservation_heatmap_total_ips,
      local.reservation_heatmap_reserved_ip_count,
      local.reservation_heatmap_total_ips - local.reservation_heatmap_reserved_ip_count,
      local.reservation_heatmap_usage_percent
    ),
    "",
    "## Reservation Heat-map",
    "",
    format("- **IPs per heat-map dot:** %d", local.reservation_heatmap_bucket_size),
    "",
    "```text",
    trimspace(local.reservation_heatmap_markdown_strip),
    "```",
    "",
    "Dots represent reserved IPs, ordered bottom-to-top and left-to-right. If ips_per_dot > 1, each dot represents up to that many IPs.",
    "",
    "## Next Free CIDRs",
    "",
    "| Prefix | CIDR | Free IPs | Available subnets |",
    "| --- | --- | ---: | ---: |"
    ], flatten([
      for cidr_size in local.scoped_cidr_sizes : length(local.next_free_cidr_suggestions_by_size[format("/%d", cidr_size)]) > 0 ? [
        for suggestion in local.next_free_cidr_suggestions_by_size[format("/%d", cidr_size)] : format(
          "| `/%d` | `%s` | %d | %d |",
          cidr_size,
          suggestion.cidr,
          suggestion.cidr_ip_count,
          suggestion.reservable_subnet_count
        )
      ] : [format("| `/%d` | None | 0 | 0 |", cidr_size)]
    ]), [
    "",
    "## Reservations",
    "",
    "| Name | CIDR or IP range |",
    "| --- | --- |"
    ], length(var.reserved) > 0 ? [
    for reservation_name in sort(keys(var.reserved)) : format(
      "| `%s` | `%s` |",
      reservation_name,
      var.reserved[reservation_name]
    )
    ] : [
    "| None | - |"
  ]))
}

output "network_report_markdown" {
  description = "Markdown report summarizing network capacity, reservations, the heat-map, and next-free CIDR suggestions."
  value       = local.network_report_markdown
}

resource "local_file" "network_report_markdown" {
  count    = var.render_report_to_file ? 1 : 0
  content  = local.network_report_markdown
  filename = var.report_file_path
}

# used for debugging the Braille character mapping, but not part of the public interface
# output "debug_braille" {
#   description = "Braille characters ordered by their IPv4 octet index."
#   value = [
#     for index in range(256) : {
#       index       = index
#       binary      = format("%08b", index)
#       hexadecimal = format("%02X", index)
#       braille     = local.ip_octet_braille[index]
#     }
#   ]
# }
