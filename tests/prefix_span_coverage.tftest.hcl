# Span coverage from 1 to 32 bits.
#
# Given current module constraints (min_prefix in 8..32):
# - spans 1..24 are valid and must compute taxative subnet counts
# - spans 25..32 are invalid because min_prefix would be < 8

run "span_1_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/31"
    min_prefix = 31
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(31, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 31)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 1-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_2_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/30"
    min_prefix = 30
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(30, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 30)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 2-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_3_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/29"
    min_prefix = 29
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(29, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 29)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 3-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_4_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/28"
    min_prefix = 28
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(28, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 28)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 4-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_5_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/27"
    min_prefix = 27
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(27, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 27)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 5-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_6_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/26"
    min_prefix = 26
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(26, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 26)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 6-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_7_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/25"
    min_prefix = 25
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(25, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 25)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 7-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_8_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(24, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 24)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 8-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_9_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/23"
    min_prefix = 23
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(23, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 23)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 9-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_10_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/22"
    min_prefix = 22
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(22, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 22)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 10-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_11_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/21"
    min_prefix = 21
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(21, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 21)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 11-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_12_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/20"
    min_prefix = 20
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(20, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 20)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 12-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_13_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/19"
    min_prefix = 19
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(19, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 19)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 13-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_14_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/18"
    min_prefix = 18
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(18, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 18)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 14-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_15_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/17"
    min_prefix = 17
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(17, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 17)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 15-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_16_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(16, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 16)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 16-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_17_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/15"
    min_prefix = 15
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(15, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 15)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 17-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_18_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/14"
    min_prefix = 14
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(14, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 14)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 18-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_19_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/13"
    min_prefix = 13
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(13, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 13)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 19-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_20_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/12"
    min_prefix = 12
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(12, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 12)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 20-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_21_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/11"
    min_prefix = 11
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(11, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 11)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 21-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_22_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/10"
    min_prefix = 10
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(10, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 10)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 22-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_23_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/9"
    min_prefix = 9
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(9, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 9)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 23-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_24_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/8"
    min_prefix = 8
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(8, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 8)
    }) && jsonencode(output.reserved) == jsonencode({})
    error_message = "A 24-bit span must produce taxative subnet counts and no reserved CIDRs when reserved are empty."
  }
}

run "span_25_bits_supported" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/7"
    min_prefix = 7
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_26_bits_supported" {
  command = plan

  variables {
    base_cidr  = "12.0.0.0/6"
    min_prefix = 6
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_27_bits_supported" {
  command = plan

  variables {
    base_cidr  = "8.0.0.0/5"
    min_prefix = 5
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_28_bits_supported" {
  command = plan

  variables {
    base_cidr  = "16.0.0.0/4"
    min_prefix = 4
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_29_bits_supported" {
  command = plan

  variables {
    base_cidr  = "32.0.0.0/3"
    min_prefix = 3
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_30_bits_supported" {
  command = plan

  variables {
    base_cidr  = "64.0.0.0/2"
    min_prefix = 2
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_31_bits_supported" {
  command = plan

  variables {
    base_cidr  = "128.0.0.0/1"
    min_prefix = 1
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

run "span_32_bits_supported" {
  command = plan

  variables {
    base_cidr  = "0.0.0.0/0"
    min_prefix = 0
    max_prefix = 32
  }

  expect_failures = [
    var.min_prefix,
  ]
}

