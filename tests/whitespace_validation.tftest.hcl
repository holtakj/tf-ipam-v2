run "base_cidr_leading_space_fails" {
  command = plan

  variables {
    base_cidr = " 10.0.0.0/16"
    min_prefix = 16
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "base_cidr_trailing_space_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16 "
    min_prefix = 16
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "base_cidr_both_spaces_fails" {
  command = plan

  variables {
    base_cidr = " 10.0.0.0/16 "
    min_prefix = 16
    max_prefix = 24
  }

  expect_failures = [
    var.base_cidr,
  ]
}

run "reservation_cidr_with_space_fails" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 24

    reserved = {
      test = " 10.0.1.0/24"
    }
  }

  expect_failures = [
    var.reserved,
  ]
}
