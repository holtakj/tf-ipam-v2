run "base_network_cidr_leading_space_fails" {
  command = plan

  variables {
    base_network_cidr = " 10.0.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24
  }

  expect_failures = [
    var.base_network_cidr,
  ]
}

run "base_network_cidr_trailing_space_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/16 "
    min_prefix_length = 16
    max_prefix_length = 24
  }

  expect_failures = [
    var.base_network_cidr,
  ]
}

run "base_network_cidr_both_spaces_fails" {
  command = plan

  variables {
    base_network_cidr = " 10.0.0.0/16 "
    min_prefix_length = 16
    max_prefix_length = 24
  }

  expect_failures = [
    var.base_network_cidr,
  ]
}

run "reservation_cidr_with_space_fails" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      test = " 10.0.1.0/24"
    }
  }

  expect_failures = [
    var.reservations,
  ]
}
