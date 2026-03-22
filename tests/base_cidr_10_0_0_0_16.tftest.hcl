run "subnet_count_map_for_10_0_0_0_16" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"
    min_prefix = 14
    max_prefix = 26
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      "/14" = 0
      "/15" = 0
      "/16" = 1
      "/17" = 2
      "/18" = 4
      "/19" = 8
      "/20" = 16
      "/21" = 32
      "/22" = 64
      "/23" = 128
      "/24" = 256
      "/25" = 512
      "/26" = 1024
    })
    error_message = "subnet_count should compute /14.../26 respecting bounds, with counts for sizes within /16.../26."
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(14, 27) : format("/%d", cidr_size) => null },
        {
          "/16" = {
            cidr_base                  = "10.0.0.0"
            size                       = 16
            cidr                       = "10.0.0.0/16"
            reservable_subnet_count    = 1
            alignment_skipped_ip_count = 0
          }
          "/17" = {
            cidr_base                  = "10.0.0.0"
            size                       = 17
            cidr                       = "10.0.0.0/17"
            reservable_subnet_count    = 2
            alignment_skipped_ip_count = 0
          }
          "/18" = {
            cidr_base                  = "10.0.0.0"
            size                       = 18
            cidr                       = "10.0.0.0/18"
            reservable_subnet_count    = 4
            alignment_skipped_ip_count = 0
          }
          "/19" = {
            cidr_base                  = "10.0.0.0"
            size                       = 19
            cidr                       = "10.0.0.0/19"
            reservable_subnet_count    = 8
            alignment_skipped_ip_count = 0
          }
          "/20" = {
            cidr_base                  = "10.0.0.0"
            size                       = 20
            cidr                       = "10.0.0.0/20"
            reservable_subnet_count    = 16
            alignment_skipped_ip_count = 0
          }
          "/21" = {
            cidr_base                  = "10.0.0.0"
            size                       = 21
            cidr                       = "10.0.0.0/21"
            reservable_subnet_count    = 32
            alignment_skipped_ip_count = 0
          }
          "/22" = {
            cidr_base                  = "10.0.0.0"
            size                       = 22
            cidr                       = "10.0.0.0/22"
            reservable_subnet_count    = 64
            alignment_skipped_ip_count = 0
          }
          "/23" = {
            cidr_base                  = "10.0.0.0"
            size                       = 23
            cidr                       = "10.0.0.0/23"
            reservable_subnet_count    = 128
            alignment_skipped_ip_count = 0
          }
          "/24" = {
            cidr_base                  = "10.0.0.0"
            size                       = 24
            cidr                       = "10.0.0.0/24"
            reservable_subnet_count    = 256
            alignment_skipped_ip_count = 0
          }
          "/25" = {
            cidr_base                  = "10.0.0.0"
            size                       = 25
            cidr                       = "10.0.0.0/25"
            reservable_subnet_count    = 512
            alignment_skipped_ip_count = 0
          }
          "/26" = {
            cidr_base                  = "10.0.0.0"
            size                       = 26
            cidr                       = "10.0.0.0/26"
            reservable_subnet_count    = 1024
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "next_free should match expected first-free values and counts for /14.../26."
  }
}

run "reserved_cidrs_must_not_overlap_check_fails_on_overlap" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"

    reserved = {
      overlap_1 = "10.0.1.0/24"
      overlap_2 = "10.0.1.128/25"
    }
  }

  expect_failures = [
    output.reserved
  ]
}

run "reserved_cidrs_must_be_unique_even_when_names_differ" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"

    reserved = {
      a = "10.0.10.0/24"
      b = "10.0.10.0/24"
    }
  }

  expect_failures = [
    output.reserved
  ]
}
