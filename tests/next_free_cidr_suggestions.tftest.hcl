run "next_free_suggestions_without_reservations" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/30"
    min_prefix_length = 30
    max_prefix_length = 32
  }

  assert {
    condition = jsonencode(output.free_cidr_suggestions) == jsonencode(merge(
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
    ))
    error_message = "Without reservations, each next-free suggestion must point at the first subnet of that size inside the base CIDR."
  }
}

run "next_free_suggestions_skip_reserved_head_subnets" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/29"
    min_prefix_length = 29
    max_prefix_length = 32

    reservations = {
      first_half = "10.0.0.0/31"
      host_3     = "10.0.0.2/32"
    }
  }

  assert {
    condition = jsonencode(output.free_cidr_suggestions) == jsonencode(merge(
      { for cidr_size in range(29, 33) : format("/%d", cidr_size) => null },
      {
        "/30" = {
          cidr_base                  = "10.0.0.4"
          size                       = 30
          cidr                       = "10.0.0.4/30"
          reservable_subnet_count    = 1
          alignment_skipped_ip_count = 1
        }
        "/31" = {
          cidr_base                  = "10.0.0.4"
          size                       = 31
          cidr                       = "10.0.0.4/31"
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 1
        }
        "/32" = {
          cidr_base                  = "10.0.0.3"
          size                       = 32
          cidr                       = "10.0.0.3/32"
          reservable_subnet_count    = 5
          alignment_skipped_ip_count = 0
        }
      }
    ))
    error_message = "When early addresses are reserved, next-free suggestions must advance to the first remaining aligned subnet of each size."
  }
}

run "next_free_suggestions_fragmented_space_across_sizes" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/28"
    min_prefix_length = 28
    max_prefix_length = 32

    reservations = {
      infra_a = "10.0.0.0/30"
      infra_b = "10.0.0.8/31"
      host_c  = "10.0.0.10/32"
    }
  }

  assert {
    condition = jsonencode(output.free_cidr_suggestions) == jsonencode(merge(
      { for cidr_size in range(28, 33) : format("/%d", cidr_size) => null },
      {
        "/30" = {
          cidr_base                  = "10.0.0.4"
          size                       = 30
          cidr                       = "10.0.0.4/30"
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 0
        }
        "/31" = {
          cidr_base                  = "10.0.0.4"
          size                       = 31
          cidr                       = "10.0.0.4/31"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 0
        }
        "/32" = {
          cidr_base                  = "10.0.0.4"
          size                       = 32
          cidr                       = "10.0.0.4/32"
          reservable_subnet_count    = 9
          alignment_skipped_ip_count = 0
        }
      }
    ))
    error_message = "Fragmented reservations must still yield the first free aligned subnet for each supported size."
  }
}

run "next_free_suggestions_hide_broader_sizes_than_base" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/24"
    min_prefix_length = 22
    max_prefix_length = 26
  }

  assert {
    condition = jsonencode(output.free_cidr_suggestions) == jsonencode(merge(
      { for cidr_size in range(22, 27) : format("/%d", cidr_size) => null },
      {
        "/24" = {
          cidr_base                  = "10.0.0.0"
          size                       = 24
          cidr                       = "10.0.0.0/24"
          reservable_subnet_count    = 1
          alignment_skipped_ip_count = 0
        }
        "/25" = {
          cidr_base                  = "10.0.0.0"
          size                       = 25
          cidr                       = "10.0.0.0/25"
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 0
        }
        "/26" = {
          cidr_base                  = "10.0.0.0"
          size                       = 26
          cidr                       = "10.0.0.0/26"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 0
        }
      }
    ))
    error_message = "Sizes broader than the base CIDR must not produce suggestions, while equal or narrower supported sizes must."
  }
}

run "next_free_suggestions_do_not_create_gap_between_touching_reservations" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/30"
    min_prefix_length = 30
    max_prefix_length = 31

    reservations = {
      lower_half = "10.0.0.0/31"
      upper_half = "10.0.0.2/31"
    }
  }

  assert {
    condition = jsonencode(output.free_cidr_suggestions) == jsonencode({
      "/30" = null
      "/31" = null
    })
    error_message = "Touching non-overlapping reservations must not create a false free segment between adjacent blocks."
  }
}
