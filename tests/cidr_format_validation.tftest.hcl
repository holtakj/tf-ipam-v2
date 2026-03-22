# CIDR format coverage tests for base_cidr and reserved.
# Includes valid IPv4 examples and invalid formats, including IPv6 variants.

run "valid_ipv4_base_format_10_0_0_0_24" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24
  }

  assert {
    condition     = output.subnet_count["/24"] == 1
    error_message = "A standard IPv4 CIDR must be accepted."
  }
}

run "valid_ipv4_base_format_172_16_0_0_20" {
  command = plan

  variables {
    base_cidr  = "172.16.0.0/20"
    min_prefix = 20
    max_prefix = 20
  }

  assert {
    condition     = output.subnet_count["/20"] == 1
    error_message = "Another standard IPv4 CIDR must be accepted."
  }
}

run "valid_subnets_enabled_cgnat_base_format_100_64_0_0_10" {
  command = plan

  variables {
    base_cidr  = "100.64.0.0/10"
    min_prefix = 10
    max_prefix = 10
  }

  assert {
    condition     = output.subnet_count["/10"] == 1
    error_message = "CGNAT space must be accepted because it is subnets-enabled for processing."
  }
}

run "unsafe_documentation_base_cidr_fails_processing" {
  command = plan

  variables {
    base_cidr  = "192.0.2.0/24"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    output.subnet_count,
  ]
}

run "invalid_base_non_canonical_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.1/24"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_missing_prefix_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_prefix_33_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/33"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_octet_out_of_range_fails" {
  command = plan

  variables {
    base_cidr  = "300.0.0.0/24"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_ipv6_compressed_fails" {
  command = plan

  variables {
    base_cidr  = "2001:db8::/32"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_ipv6_expanded_fails" {
  command = plan

  variables {
    base_cidr  = "2001:0db8:0000:0000:0000:ff00:0042:8329/64"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_base_ipv4_mapped_ipv6_fails" {
  command = plan

  variables {
    base_cidr  = "::ffff:192.0.2.128/128"
    min_prefix = 24
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "invalid_reservation_missing_prefix_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24

    reserved = {
      bad = "10.0.0.10"
    }
  }

  expect_failures = [
    var.reserved,
  ]
}

run "invalid_reservation_empty_name_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24

    reserved = {
      "" = "10.0.0.0/24"
    }
  }

  expect_failures = [
    var.reserved,
  ]
}

run "invalid_reservation_ipv6_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24

    reserved = {
      bad = "2001:db8::/64"
    }
  }

  expect_failures = [
    var.reserved,
  ]
}

run "invalid_reservation_non_canonical_fails" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24

    reserved = {
      bad = "10.0.0.1/30"
    }
  }

  expect_failures = [
    var.reserved,
  ]
}
