# Tests for min_prefix and max_prefix extremes.
#
# Valid range: both 8..32 and max >= min.

# ── Passing: valid extreme combinations ──────────────────────────────────────

# Both prefix limits equal the base prefix → exactly one size computed at count 1.
run "min_max_equal_base_prefix_computes_single_size" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 24
  }

  assert {
    condition     = output.subnet_count["/24"] == 1 && length(output.subnet_count) == 1
    error_message = "When min == max == base prefix, subnet_count must only contain /24 with count 1."
  }

  assert {
    condition     = output.next_free["/24"][0].cidr == "10.0.0.0/24" && length(output.next_free) == 1
    error_message = "When min == max == base prefix, next_free must only contain /24 with the expected CIDR."
  }
}

# max at a formerly constrained 12-bit span boundary: max - min = 32 - 20 = 12.
run "max_prefix_length_at_exact_12_bit_span_boundary" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/22"
    min_prefix = 20
    max_prefix = 32
  }

  assert {
    condition     = output.subnet_count["/22"] == 1
    error_message = "At the 12-bit span boundary, /22 should have count 1."
  }

  assert {
    condition     = output.subnet_count["/32"] == 1024
    error_message = "At the 12-bit span boundary, /32 should have count 1024."
  }
}

run "max_prefix_length_more_than_12_bits_above_min_now_passes" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/19"
    min_prefix = 19
    max_prefix = 32
  }

  assert {
    condition     = output.subnet_count["/19"] == 1
    error_message = "For a 13-bit span, /19 should have count 1."
  }

  assert {
    condition     = output.subnet_count["/32"] == 8192
    error_message = "For a 13-bit span, /32 should have count 8192."
  }

  assert {
    condition     = output.next_free["/32"][0].cidr == "10.0.0.0/32"
    error_message = "For a 13-bit span, the first suggested /32 must be 10.0.0.0/32."
  }
}

# Narrowest possible: base /32, min 32, max 32 → single host route, nothing else.
run "min_max_at_32_single_host_route" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/32"
    min_prefix = 32
    max_prefix = 32
  }

  assert {
    condition     = output.subnet_count["/32"] == 1
    error_message = "A /32 base with min=max=32 must yield exactly one /32 in subnet_count."
  }

  assert {
    condition     = output.next_free["/32"][0].cidr == "10.0.0.0/32"
    error_message = "A /32 base with min=max=32 must suggest 10.0.0.0/32."
  }

  assert {
    condition     = length(output.next_free) == 1
    error_message = "A /32 base with min=max=32 should only return /32 in next_free."
  }
}

# Broadest allowed is /8 now, so /1 bounds must fail variable validation.
run "min_max_at_1_broadest_network_fails_variable_validation" {
  command = plan

  variables {
    base_cidr = "0.0.0.0/1"
    min_prefix = 1
    max_prefix = 1
  }

  expect_failures = [
    var.min_prefix,
    var.max_prefix,
  ]
}

# ── Failing: check block violations ──────────────────────────────────────────

# base_cidr prefix (7) is lower than min_prefix (8).
run "base_cidr_broader_than_min_prefix_length_passes" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/7"
    min_prefix = 8
    max_prefix = 8
  }

  assert {
    condition     = output.subnet_count["/8"] == 2
    error_message = "A /7 base should contain 2 /8 subnets."
  }
}

# max_prefix (23) < min_prefix (24) → inverted range.
run "max_prefix_length_below_min_prefix_length_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 23
  }

  expect_failures = [
    output.subnet_count,
  ]
}

# base_cidr prefix (28) is higher than max_prefix (24).
run "base_cidr_narrower_than_max_prefix_length_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/28"
    min_prefix = 20
    max_prefix = 24
  }

  expect_failures = [
    output.subnet_count,
  ]
}

# ── Failing: variable validation violations ───────────────────────────────────

# min_prefix = 0 is below the valid range of 8..32.
run "min_prefix_length_zero_out_of_range_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    min_prefix = 0
    max_prefix = 24
  }

  expect_failures = [
    var.min_prefix,
  ]
}

# max_prefix = 33 is above the valid range of 8..32.
run "max_prefix_length_33_out_of_range_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 33
  }

  expect_failures = [
    var.max_prefix,
  ]
}

