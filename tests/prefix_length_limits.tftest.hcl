# Tests for min_prefix_length and max_prefix_length extremes.
#
# Valid range: both 8..32 and max >= min.

# ── Passing: valid extreme combinations ──────────────────────────────────────

# Both prefix limits equal the base prefix → exactly one size computed at count 1.
run "min_max_equal_base_prefix_computes_single_size" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/24"
    min_prefix_length = 24
    max_prefix_length = 24
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/24"] == 1 && length(output.subnet_count_by_cidr_size) == 1
    error_message = "When min == max == base prefix, subnet_count_by_cidr_size must only contain /24 with count 1."
  }

  assert {
    condition     = output.free_cidr_suggestions["/24"].cidr == "10.0.0.0/24" && length(output.free_cidr_suggestions) == 1
    error_message = "When min == max == base prefix, free_cidr_suggestions must only contain /24 with the expected CIDR."
  }
}

# max at a formerly constrained 12-bit span boundary: max - min = 32 - 20 = 12.
run "max_prefix_length_at_exact_12_bit_span_boundary" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/22"
    min_prefix_length = 20
    max_prefix_length = 32
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/22"] == 1
    error_message = "At the 12-bit span boundary, /22 should have count 1."
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/32"] == 1024
    error_message = "At the 12-bit span boundary, /32 should have count 1024."
  }
}

run "max_prefix_length_more_than_12_bits_above_min_now_passes" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/19"
    min_prefix_length = 19
    max_prefix_length = 32
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/19"] == 1
    error_message = "For a 13-bit span, /19 should have count 1."
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/32"] == 8192
    error_message = "For a 13-bit span, /32 should have count 8192."
  }

  assert {
    condition     = output.free_cidr_suggestions["/32"].cidr == "10.0.0.0/32"
    error_message = "For a 13-bit span, the first suggested /32 must be 10.0.0.0/32."
  }
}

# Narrowest possible: base /32, min 32, max 32 → single host route, nothing else.
run "min_max_at_32_single_host_route" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/32"
    min_prefix_length = 32
    max_prefix_length = 32
  }

  assert {
    condition     = output.subnet_count_by_cidr_size["/32"] == 1
    error_message = "A /32 base with min=max=32 must yield exactly one /32 in subnet_count_by_cidr_size."
  }

  assert {
    condition     = output.free_cidr_suggestions["/32"].cidr == "10.0.0.0/32"
    error_message = "A /32 base with min=max=32 must suggest 10.0.0.0/32."
  }

  assert {
    condition     = length(output.free_cidr_suggestions) == 1
    error_message = "A /32 base with min=max=32 should only return /32 in free_cidr_suggestions."
  }
}

# Broadest allowed is /8 now, so /1 bounds must fail variable validation.
run "min_max_at_1_broadest_network_fails_variable_validation" {
  command = plan

  variables {
    base_network_cidr = "0.0.0.0/1"
    min_prefix_length = 1
    max_prefix_length = 1
  }

  expect_failures = [
    var.min_prefix_length,
    var.max_prefix_length,
  ]
}

# ── Failing: check block violations ──────────────────────────────────────────

# base_network_cidr prefix (7) is lower than min_prefix_length (8).
run "base_network_cidr_broader_than_min_prefix_length_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/7"
    min_prefix_length = 8
    max_prefix_length = 8
  }

  expect_failures = [
    output.subnet_count_by_cidr_size,
  ]
}

# max_prefix_length (23) < min_prefix_length (24) → inverted range.
run "max_prefix_length_below_min_prefix_length_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/24"
    min_prefix_length = 24
    max_prefix_length = 23
  }

  expect_failures = [
    output.subnet_count_by_cidr_size,
  ]
}

# base_network_cidr prefix (28) is higher than max_prefix_length (24).
run "base_network_cidr_narrower_than_max_prefix_length_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/28"
    min_prefix_length = 20
    max_prefix_length = 24
  }

  expect_failures = [
    output.subnet_count_by_cidr_size,
  ]
}

# ── Failing: variable validation violations ───────────────────────────────────

# min_prefix_length = 0 is below the valid range of 8..32.
run "min_prefix_length_zero_out_of_range_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/24"
    min_prefix_length = 0
    max_prefix_length = 24
  }

  expect_failures = [
    var.min_prefix_length,
  ]
}

# max_prefix_length = 33 is above the valid range of 8..32.
run "max_prefix_length_33_out_of_range_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/24"
    min_prefix_length = 24
    max_prefix_length = 33
  }

  expect_failures = [
    var.max_prefix_length,
  ]
}

