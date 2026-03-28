run "ip_range_blocks_free_space_like_equivalent_cidr" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32

    # Reserve the first half of the /24 (10.0.0.0–10.0.0.127) using an IP range.
    # The second half (10.0.0.128/25) must remain free.
    reserved = {
      "first-half" = "10.0.0.0-10.0.0.127"
    }
  }

  assert {
    condition = (
      output.next_free_cidrs["/25"][0].cidr == "10.0.0.128/25" &&
      output.next_free_cidrs["/26"][0].cidr == "10.0.0.128/26"
    )
    error_message = "An IP range reservation of the first /25 must leave 10.0.0.128/25 as the first free /25."
  }
}

run "ip_range_10000_addresses_in_16_base" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 32

    # Reserve exactly 10 000 IP addresses at the start of the /16.
    # 10.0.0.0  = offset 0, 10.0.39.15 = offset 9999 → 10 000 IPs inclusive.
    # Free segment starts at 10.0.39.16 (offset 10 000) through 10.0.255.255 (offset 65 535).
    #
    # First free /26 (size 64): ceil(10000/64) = 157 → offset 10048 = 10.0.39.64/26.
    # First free /24 (size 256): ceil(10000/256) = 40 → offset 10240 = 10.0.40.0/24.
    # Reservable /24 count: indices 40..255 = 216 free /24 blocks.
    reserved = {
      "first-10000" = "10.0.0.0-10.0.39.15"
    }
  }

  assert {
    condition = (
      output.next_free_cidrs["/26"][0].cidr == "10.0.39.64/26" &&
      output.next_free_cidrs["/24"][0].cidr == "10.0.40.0/24" &&
      output.next_free_cidrs["/24"][0].reservable_subnet_count == 216
    )
    error_message = "A 10000-IP range reservation must leave 10.0.39.64/26 as first free /26, 10.0.40.0/24 as first free /24, and exactly 216 free /24 blocks."
  }
}

run "ip_range_and_cidr_mixed_reservations" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32

    # Reserve 10.0.0.0/26 as a CIDR and 10.0.0.192-10.0.0.255 as an IP range.
    # Free space: 10.0.0.64/26 and 10.0.0.128/26.
    reserved = {
      "cidr-entry"  = "10.0.0.0/26"
      "range-entry" = "10.0.0.192-10.0.0.255"
    }
  }

  assert {
    condition = (
      output.next_free_cidrs["/26"][0].cidr == "10.0.0.64/26" &&
      output.next_free_cidrs["/26"][0].reservable_subnet_count == 2
    )
    error_message = "Mixed CIDR and IP range reservations must leave exactly the two middle /26 blocks free."
  }
}
