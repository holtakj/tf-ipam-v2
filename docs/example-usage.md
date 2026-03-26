# Example Usage

This document provides practical examples of how to consume `tf-ipam-v2` outputs.

## Basic Module Invocation

```hcl
module "ipam" {
  source = "../"

  base_cidr    = "10.42.0.0/16"
  min_prefix   = 20
  max_prefix   = 26
  suggest_count = 2

  reserved = {
    platform = "10.42.0.0/20"
    data     = "10.42.32.0/20"
    edge     = "10.42.64.0/21"
  }

## Reserving an Arbitrary IP Range

Use `start-end` notation to block an address range that does not align to a
CIDR boundary (for example, a legacy allocation handed over without a prefix):

```hcl
module "ipam" {
  source = "../"

  base_cidr = "10.42.0.0/16"

  reserved = {
    platform      = "10.42.0.0/20"            # canonical CIDR
    legacy_legacy = "10.42.20.0-10.42.20.199" # arbitrary IP range (200 addresses)
  }
}
```

IP range values must satisfy:
- Format: `A.B.C.D-E.F.G.H` (no spaces, valid IPv4 octets)
- `start <= end`
- Both addresses fall within `base_cidr`
- Range does not overlap any other reservation
}
```

## Read Capacity by Prefix

```hcl
output "capacity_24" {
  value = module.ipam.subnet_count["/24"]
}
```

## Read First Suggested CIDR for /24

```hcl
output "next_free_24" {
  value = try(module.ipam.next_free_cidr["/24"], null)
}
```

## Read Multiple Suggested CIDRs for /24

```hcl
output "next_free_24_candidates" {
  value = module.ipam.next_free_cidrs["/24"]
}
```

## Expected Suggestion Object Shape

```hcl
{
  cidr_base                  = "10.42.8.0"
  size                       = 24
  cidr                       = "10.42.8.0/24"
  reservable_subnet_count    = 200
  alignment_skipped_ip_count = 0
}

## Read Reserved Usage Percentage by Prefix

```hcl
output "usage_24" {
  value = module.ipam.subnet_usage_by_size["/24"]
}
```

Expected shape:

```hcl
{
  reservable_subnet_count    = 200
  reserved_subnet_count      = 56
  reserved_subnet_percentage = 21.875
}
```
```

## Echoed Reservations

```hcl
output "reserved_map" {
  value = module.ipam.reserved
}
```

This output returns the validated reservation map as `name -> value`, where each
value is either a canonical CIDR string or an `start-end` IP range string,
exactly as supplied in the `reserved` input.
