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

### Runtime Provider Dependency

This module uses the [`The-DevOps-Daily/validatefx`](https://registry.terraform.io/providers/The-DevOps-Daily/validatefx) provider (`>= 0.11.2`) for CIDR overlap validation via `provider::validatefx::cidr_overlap`. The provider is **not** declared in the module's `required_providers` to preserve flexibility for consuming root configurations. The root configuration must declare it:

```hcl
terraform {
  required_providers {
    validatefx = {
      source  = "registry.terraform.io/The-DevOps-Daily/validatefx"
      version = ">= 0.11.2"
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `base_network_cidr` | `string` | n/a | Base IPv4 CIDR block for IPAM allocations (for example `10.0.0.0/16`). |
| `min_prefix_length` | `number` | `8` | Broadest/largest prefix included in computation/reservations (`8..32`). |
| `max_prefix_length` | `number` | `32` | Narrowest/smallest prefix included in computation/reservations (`8..32`). |
| `reservations` | `map(string)` | `{}` | Map of reservation name to canonical CIDR. Names are stable keys; CIDRs must be canonical, valid, and non-overlapping. |

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `subnet_count_by_cidr_size` | `map(number)` | Number of subnets that can be carved from `base_network_cidr` for each CIDR size key (`"/<min_prefix_length>"..."/<max_prefix_length>"`). |
| `free_cidr_suggestions` | `map(object \| null)` | For each size key (`"/<min_prefix_length>"..."/<max_prefix_length>"`), either `null` or `{ cidr_base, size, cidr, reservable_subnet_count, alignment_skipped_ip_count }`. |
| `reserved` | `map(string)` | Echo of reservations (name -> CIDR). |

## Validation Rules

The module enforces:

- `max_prefix_length >= min_prefix_length`
- `base_network_cidr` is canonical (host bits zeroed, for example `10.0.0.0/24`)
- `base_network_cidr` prefix is not broader than `min_prefix_length`
- `base_network_cidr` prefix is not narrower than `max_prefix_length`
- reservation CIDR values are unique
- reservation CIDRs are canonical/aligned/in range for current bounds
- reservation CIDRs do not overlap (`validatefx::cidr_overlap`)

## Algorithm Overview

1. Convert `base_network_cidr` and reservation CIDRs into integer ranges.
2. Sort and intersect reservation ranges against the base range.
3. Derive contiguous free IP segments between reserved ranges.
4. For each CIDR size, convert free segments into valid aligned subnet index intervals.
5. Aggregate interval lengths into `reservable_subnet_count`.
6. Materialize first valid index as the `next_free` suggestion.

This produces deterministic results with predictable complexity even for large spans.

## Testing

Tests require the `validatefx` provider. The `test.sh` wrapper script temporarily injects the provider declaration, runs `terraform init` and `terraform test`, then cleans up:

```bash
./test.sh
```

Any arguments are forwarded to `terraform test`:

```bash
./test.sh -filter=base_10_0_0_0_16.tftest.hcl
```

## Usage

```hcl
module "ipam" {
  source = "./terraform/modules/tf-ipam-v2"

  base_network_cidr = "10.0.0.0/16"
  min_prefix_length = 16
  max_prefix_length = 26

  reservations = {
    dmz = "10.0.8.0/24"
    db  = "10.0.16.0/20"
  }
}
```

### Example: Read next-free `/24`

```hcl
output "next_free_24" {
  value = module.ipam.free_cidr_suggestions["/24"]
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

## Testing

From module directory:

```bash
terraform test
```

The repository includes taxative tests for prefix spans, next-free behavior, alignment skip counts, and limit guardrails.

## License

This module is licensed under the MIT License. See `LICENSE`.
