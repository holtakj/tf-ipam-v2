# tf-ipam-v2

Terraform module for deterministic IPv4 subnet capacity analysis and "next free" subnet suggestions.

## Features

- Computes subnet capacity by CIDR size (`/8`..`/32` within configured bounds).
- Validates reservation CIDRs for canonical format, alignment, range, uniqueness, and overlap.
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
| `reserved` | `map(string)` | `{}` | Map of reservation name to canonical CIDR. Names are stable keys; CIDRs must be canonical, valid, and non-overlapping. |
| `suggest_count` | `number` | `1` | Number of next-free CIDR suggestions to return per size key (`1..1024`). |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `subnet_count` | `map(number)` | Number of subnets that can be carved from `base_cidr` for each CIDR size key (`"/<min_prefix>"..."/<max_prefix>"`). |
| `next_free_cidrs` | `map(list(object))` | For each size key (`"/<min_prefix>"..."/<max_prefix>"`), a list (possibly empty) of up to `suggest_count` objects `{ cidr_base, size, cidr, reservable_subnet_count, alignment_skipped_ip_count }`. |
| `next_free_cidr` | `map(object \| null)` | For each size key (`"/<min_prefix>"..."/<max_prefix>"`), the first next-free suggestion object or `null` when unavailable. Object fields: `{ cidr_base, size, cidr, reservable_subnet_count, alignment_skipped_ip_count }`. |
| `reserved` | `map(string)` | Echo of reserved CIDRs (name -> CIDR). |

## Validation Rules

The module enforces:

- `max_prefix >= min_prefix`
- `base_cidr` must be in a subnets-enabled category (`private_use` or `carrier_grade_nat`)
- `base_cidr` is canonical (host bits zeroed, for example `10.0.0.0/24`)
- `base_cidr` prefix is not broader than `min_prefix`
- `base_cidr` prefix is not narrower than `max_prefix`
- reservation CIDR values are unique
- reservation CIDRs are canonical/aligned/in range for current bounds
- reservation CIDRs do not overlap (native sorted-range check, O(n log n))

Allowed subnet-processing categories are defined in `ipv4_space_categories.tf` via the `subnets` flag.

## Algorithm Overview

1. Convert `base_cidr` and reservation CIDRs into integer ranges.
2. Sort reservation ranges and verify adjacent pairs are disjoint (overlap validation in O(n log n)).
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
    dmz = "10.0.8.0/24"
    db  = "10.0.16.0/20"
  }
}
```

### Example: Read first next-free `/24`

```hcl
output "next_free_24" {
  value = try(module.ipam.next_free_cidr["/24"], null)
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
