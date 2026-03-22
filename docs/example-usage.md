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
```

## Echoed Reservations

```hcl
output "reserved_map" {
  value = module.ipam.reserved
}
```

This output returns the validated reservation map as `name -> cidr`.
