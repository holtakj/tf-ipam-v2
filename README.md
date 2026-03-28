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

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `subnet_count` | `map(number)` | Number of subnets that can be carved from `base_cidr` for each CIDR size key (`"/<min_prefix>"..."/<max_prefix>"`). |
| `next_free_cidrs` | `map(list(object))` | For each size key (`"/<min_prefix>"..."/<max_prefix>"`), a list (possibly empty) of up to `suggest_count` objects `{ cidr_base, cidr_size, cidr, cidr_ip_count, reservable_subnet_count, alignment_skipped_ip_count }`. |
| `zzz_graph` | `object` | Terminal-friendly heat-map of IP space usage. Fields: `base_cidr`, `bucket_count`, `bucket_size_ips`, `legend`, `heatmap` (64-char strip). Printed last due to lexicographic output ordering. |
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

The repository includes taxative tests for prefix spans, next-free behavior, alignment skip counts, and limit guardrails.

## License

This module is licensed under the MIT License. See `LICENSE`.
