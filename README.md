# tf-ipam-v2

Terraform module for deterministic IPv4 subnet capacity analysis and "next free" subnet suggestions.

## Features

- Computes subnet capacity by CIDR size (`/8`..`/32` within configured bounds).
- Validates reservations (canonical CIDRs or IP ranges) for format, alignment/bounds, uniqueness, and overlap.
- Returns first allocatable aligned subnet per size plus count of remaining reservable subnets.
- Uses interval/range math (no brute-force candidate list generation).

## IPv4 Support Only

This module supports **IPv4 only**.

- All CIDR parsing and math assume 32-bit IPv4 addresses.
- IPv6 CIDRs are not supported and will fail validation/processing.

## Requirements

| Name | Version |
| --- | --- |
| Terraform | `>= 1.8.0` |

## Documentation

- Detailed examples: [docs/example-usage.md](docs/example-usage.md)

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `base_cidr` | `string` | n/a | Base IPv4 CIDR block for IPAM allocations (for example `10.0.0.0/16`). |
| `min_prefix` | `number` | `8` | Broadest/largest prefix included in computation and reserved CIDRs (`8..32`). |
| `max_prefix` | `number` | `32` | Narrowest/smallest prefix included in computation and reserved CIDRs (`8..32`). |
| `reserved` | `map(string)` | `{}` | Map of reservation name to a canonical IPv4 CIDR (e.g. `10.0.0.0/24`) **or** an IP range in `start-end` notation (e.g. `10.0.1.0-10.0.1.255`). Names are stable keys; values must be valid, non-overlapping, and within `base_cidr`. |
| `suggest_count` | `number` | `1` | Number of next-free CIDR suggestions to return per size key (`1..1024`). |
| `render_report_to_file` | `bool` | `false` | Write the Markdown report to the configured path when enabled. |
| `report_file_path` | `string` | `network_report.md` | Path and filename for the Markdown report. Relative paths are resolved from the Terraform working directory. |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `subnet_count` | `map(number)` | Number of subnets that can be carved from `base_cidr` for each CIDR size key (`"/<min_prefix>"..."/<max_prefix>"`). |
| `next_free_cidrs` | `map(list(object))` | For each size key (`"/<min_prefix>"..."/<max_prefix>"`), a list (possibly empty) of up to `suggest_count` objects `{ cidr_base, cidr_size, cidr, cidr_ip_count, reservable_subnet_count, alignment_skipped_ip_count }`. |
| `zzz_graph` | `object` | Terminal-friendly Braille heat-map of IP space usage. Fields: `base_cidr`, `total_ip_count`, `ips_per_dot`, `usage_percent`, `legend`, `heatmap` (up to 64 Braille characters per labeled line). Printed last due to lexicographic output ordering. |
| `network_report_markdown` | `string` | Markdown report with capacity, utilization, the Braille heat-map, and next-free CIDR suggestions. |
| `reserved` | `map(string)` | Echo of the reservation map (name -> CIDR or IP range). |

## Validation Rules

The module enforces:

- `max_prefix >= min_prefix`
- `base_cidr` must be in a subnets-enabled category (`private_use` or `carrier_grade_nat`)
- `base_cidr` is canonical (host bits zeroed, for example `10.0.0.0/24`)
- `base_cidr` prefix is not broader than `min_prefix`
- `base_cidr` prefix is not narrower than `max_prefix`
- reservation values are unique
- CIDR reservations are canonical, aligned, and within `[min_prefix, max_prefix]` bounds
- IP range reservations have `start <= end` and fall within `base_cidr`
- all reservations (CIDRs and IP ranges) do not overlap (sorted-range check, O(n log n))

Allowed subnet-processing categories are defined in `ipv4_space_categories.tf` via the `subnets` flag.

## Algorithm Overview

1. Convert `base_cidr` and all reservations (CIDRs and IP ranges) into integer `[start, end]` ranges.
2. Sort all reservation ranges and verify adjacent pairs are disjoint (overlap validation in O(n log n)).
3. Intersect reservation ranges against the base range.
4. Derive contiguous free IP segments between reserved ranges.
5. For each CIDR size, convert free segments into valid aligned subnet index intervals.
6. Aggregate interval lengths into `reservable_subnet_count`.
7. Materialize first valid index as the `next_free_cidr` suggestion.

This produces deterministic results with predictable complexity even for large spans.

## Testing

The `test.sh` wrapper script runs `terraform init`, `terraform validate`, and `terraform test`:

```bash
./test.sh
```

Any arguments are forwarded to `terraform test`:

```bash
./test.sh -filter=base_cidr_10_0_0_0_16.tftest.hcl
```

## Usage

```hcl
module "ipam" {
  source = "./terraform/modules/tf-ipam-v2"

  base_cidr = "10.0.0.0/16"
  min_prefix = 16
  max_prefix = 26

  reserved = {
    dmz        = "10.0.8.0/24"
    db         = "10.0.16.0/20"
    quarantine = "10.0.24.0-10.0.24.63"  # IP range (not required to align to a CIDR boundary)
  }

  render_report_to_file = true
  report_file_path      = "reports/network_report.md"
}
```

### Example: Read up to N next-free `/24` suggestions

```hcl
output "next_free_24_candidates" {
  value = module.ipam.next_free_cidrs["/24"]
}
```

### Example output object

```hcl
{
  cidr_base                  = "10.0.0.0"
  size                       = 24
  cidr                       = "10.0.0.0/24"
  reservable_subnet_count    = 239
  alignment_skipped_ip_count = 0
}
```

### Example network report

`network_report_markdown` produces a terminal-friendly Markdown summary in the output, including a heat-map of reserved vs. free IPs and a table of next-free CIDR suggestions.

```markdown
# TF-IPAM Network report

- **Base CIDR:** `10.0.0.0/15`
- **Prefix range:** `/24` to `/32`
- **Reservations:** 5

## Capacity

| Total IPs | Reserved IPs | Available IPs | Utilization |
| ---: | ---: | ---: | ---: |
| 131072 | 423 | 130649 | 0.32272% |

## Reservation Heat-map

- **IPs per heat-map dot:** 8

```text
10.0.0.0       |⣿⣦⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.15.255    
10.0.16.0      |⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.31.255    
10.0.32.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.47.255    
10.0.48.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.63.255    
10.0.64.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.79.255    
10.0.80.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.95.255    
10.0.96.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.111.255   
10.0.112.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.127.255   
10.0.128.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.143.255   
10.0.144.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.159.255   
10.0.160.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.175.255   
10.0.176.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.191.255   
10.0.192.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.207.255   
10.0.208.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.223.255   
10.0.224.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.239.255   
10.0.240.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.0.255.255   
10.1.0.0       |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.15.255    
10.1.16.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.31.255    
10.1.32.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.47.255    
10.1.48.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.63.255    
10.1.64.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.79.255    
10.1.80.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.95.255    
10.1.96.0      |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.111.255   
10.1.112.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.127.255   
10.1.128.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.143.255   
10.1.144.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.159.255   
10.1.160.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.175.255   
10.1.176.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.191.255   
10.1.192.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.207.255   
10.1.208.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.223.255   
10.1.224.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.239.255   
10.1.240.0     |⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀| 10.1.255.255
```

Dots represent reserved IPs, ordered bottom-to-top and left-to-right. If ips_per_dot > 1, each dot represents up to that many IPs.

## Next Free CIDRs

| Prefix | CIDR | Free IPs | Available subnets |
| --- | --- | ---: | ---: |
| `/24` | `10.0.1.0/24` | 256 | 508 |
| `/24` | `10.0.2.0/24` | 256 | 508 |
| `/24` | `10.0.3.0/24` | 256 | 508 |
| `/24` | `10.0.4.0/24` | 256 | 508 |
| `/24` | `10.0.5.0/24` | 256 | 508 |
| `/25` | `10.0.1.0/25` | 128 | 1018 |
| `/25` | `10.0.1.128/25` | 128 | 1018 |
| `/25` | `10.0.2.0/25` | 128 | 1018 |
| `/25` | `10.0.2.128/25` | 128 | 1018 |
| `/25` | `10.0.3.0/25` | 128 | 1018 |
| `/26` | `10.0.0.192/26` | 64 | 2039 |
| `/26` | `10.0.1.0/26` | 64 | 2039 |
| `/26` | `10.0.1.64/26` | 64 | 2039 |
| `/26` | `10.0.1.128/26` | 64 | 2039 |
| `/26` | `10.0.1.192/26` | 64 | 2039 |
| `/27` | `10.0.0.192/27` | 32 | 4080 |
| `/27` | `10.0.0.224/27` | 32 | 4080 |
| `/27` | `10.0.1.0/27` | 32 | 4080 |
| `/27` | `10.0.1.32/27` | 32 | 4080 |
| `/27` | `10.0.1.64/27` | 32 | 4080 |
| `/28` | `10.0.0.112/28` | 16 | 8163 |
| `/28` | `10.0.0.192/28` | 16 | 8163 |
| `/28` | `10.0.0.208/28` | 16 | 8163 |
| `/28` | `10.0.0.224/28` | 16 | 8163 |
| `/28` | `10.0.0.240/28` | 16 | 8163 |
| `/29` | `10.0.0.104/29` | 8 | 16329 |
| `/29` | `10.0.0.112/29` | 8 | 16329 |
| `/29` | `10.0.0.120/29` | 8 | 16329 |
| `/29` | `10.0.0.192/29` | 8 | 16329 |
| `/29` | `10.0.0.200/29` | 8 | 16329 |
| `/30` | `10.0.0.104/30` | 4 | 32660 |
| `/30` | `10.0.0.108/30` | 4 | 32660 |
| `/30` | `10.0.0.112/30` | 4 | 32660 |
| `/30` | `10.0.0.116/30` | 4 | 32660 |
| `/30` | `10.0.0.120/30` | 4 | 32660 |
| `/31` | `10.0.0.102/31` | 2 | 65323 |
| `/31` | `10.0.0.104/31` | 2 | 65323 |
| `/31` | `10.0.0.106/31` | 2 | 65323 |
| `/31` | `10.0.0.108/31` | 2 | 65323 |
| `/31` | `10.0.0.110/31` | 2 | 65323 |
| `/32` | `10.0.0.101/32` | 1 | 130649 |
| `/32` | `10.0.0.102/32` | 1 | 130649 |
| `/32` | `10.0.0.103/32` | 1 | 130649 |
| `/32` | `10.0.0.104/32` | 1 | 130649 |
| `/32` | `10.0.0.105/32` | 1 | 130649 |

## Reservations

| Name | CIDR or IP range |
| --- | --- |
| `range` | `10.0.16.0-10.0.16.255` |
| `one_dot_at_the_end` | `10.0.7.254/32` |
| `quarantine` | `10.0.0.0-10.0.0.100` |
| `single_ip` | `10.0.8.100` |
| `subnet` | `10.0.0.128/26` |
```

See the [complete example report](manual-test/network_report.md), including the
reservation heat-map and all suggested CIDRs.

The repository includes taxative tests for prefix spans, next-free behavior, alignment skip counts, and limit guardrails.

## License

This module is licensed under the MIT License. See `LICENSE`.
