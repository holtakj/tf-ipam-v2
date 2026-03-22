run "alignment_skipped_ip_count_is_zero_without_reservations" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/30"
    min_prefix = 30
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(30, 33) : format("/%d", cidr_size) => null },
        {
          "/30" = {
            cidr_base                  = "10.0.0.0"
            size                       = 30
            cidr                       = "10.0.0.0/30"
            reservable_subnet_count    = 1
            alignment_skipped_ip_count = 0
          }
          "/31" = {
            cidr_base                  = "10.0.0.0"
            size                       = 31
            cidr                       = "10.0.0.0/31"
            reservable_subnet_count    = 2
            alignment_skipped_ip_count = 0
          }
          "/32" = {
            cidr_base                  = "10.0.0.0"
            size                       = 32
            cidr                       = "10.0.0.0/32"
            reservable_subnet_count    = 4
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "Without reserved, alignment_skipped_ip_count must be 0 for every suggested size."
  }
}

run "alignment_skipped_ip_count_counts_only_free_ips_before_first_aligned_subnet" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/29"
    min_prefix = 29
    max_prefix = 32

    reserved = {
      first_ip = "10.0.0.0/32"
      third_ip = "10.0.0.2/32"
    }
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(29, 33) : format("/%d", cidr_size) => null },
        {
          "/30" = {
            cidr_base                  = "10.0.0.4"
            size                       = 30
            cidr                       = "10.0.0.4/30"
            reservable_subnet_count    = 1
            alignment_skipped_ip_count = 2
          }
          "/31" = {
            cidr_base                  = "10.0.0.4"
            size                       = 31
            cidr                       = "10.0.0.4/31"
            reservable_subnet_count    = 2
            alignment_skipped_ip_count = 2
          }
          "/32" = {
            cidr_base                  = "10.0.0.1"
            size                       = 32
            cidr                       = "10.0.0.1/32"
            reservable_subnet_count    = 6
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "alignment_skipped_ip_count must count only free /32 IPs before the first aligned subnet, not the raw absolute IP offset."
  }
}

run "alignment_skipped_ip_count_large_16_base_network" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 28
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(16, 29) : format("/%d", cidr_size) => null },
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
          "/27" = {
            cidr_base                  = "10.0.0.0"
            size                       = 27
            cidr                       = "10.0.0.0/27"
            reservable_subnet_count    = 2048
            alignment_skipped_ip_count = 0
          }
          "/28" = {
            cidr_base                  = "10.0.0.0"
            size                       = 28
            cidr                       = "10.0.0.0/28"
            reservable_subnet_count    = 4096
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "For a large /16 base with min=16 and max=28, the map must be fully taxative and alignment_skipped_ip_count must be 0 because /32 candidates are not computed in this range."
  }
}

run "alignment_skipped_ip_count_is_computed_when_32_is_out_of_scope" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/29"
    min_prefix = 29
    max_prefix = 31

    reserved = {
      reserved_head = "10.0.0.0/31"
    }
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(29, 32) : format("/%d", cidr_size) => null },
        {
          "/30" = {
            cidr_base                  = "10.0.0.4"
            size                       = 30
            cidr                       = "10.0.0.4/30"
            reservable_subnet_count    = 1
            alignment_skipped_ip_count = 2
          }
          "/31" = {
            cidr_base                  = "10.0.0.2"
            size                       = 31
            cidr                       = "10.0.0.2/31"
            reservable_subnet_count    = 3
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "alignment_skipped_ip_count must still be computed from free-space overlap even when /32 is outside max_prefix."
  }
}