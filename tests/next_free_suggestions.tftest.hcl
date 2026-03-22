run "next_free_suggestions_without_reservations" {
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
    error_message = "Without reserved, each next-free suggestion must point at the first subnet of that size inside the base CIDR."
  }

  assert {
    condition = jsonencode(output.next_free_cidr) == jsonencode({
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
    })
    error_message = "next_free must expose only the first suggestion per subnet size."
  }
}

run "next_free_suggestions_skip_reserved_head_subnets" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/29"
    min_prefix = 29
    max_prefix = 32

    reserved = {
      first_half = "10.0.0.0/31"
      host_3     = "10.0.0.2/32"
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
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "When early addresses are reserved, next-free suggestions must advance to the first remaining aligned subnet of each size."
  }
}

run "next_free_suggestions_fragmented_space_across_sizes" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/28"
    min_prefix = 28
    max_prefix = 32

    reserved = {
      infra_a = "10.0.0.0/30"
      infra_b = "10.0.0.8/31"
      host_c  = "10.0.0.10/32"
    }
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
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
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "Fragmented reserved must still yield the first free aligned subnet for each supported size."
  }
}

run "next_free_suggestions_hide_broader_sizes_than_base" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 22
    max_prefix = 26
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      for cidr_key, suggestion in merge(
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
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "Sizes broader than the base CIDR must not produce suggestions, while equal or narrower supported sizes must."
  }
}

run "next_free_suggestions_do_not_create_gap_between_touching_reservations" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/30"
    min_prefix = 30
    max_prefix = 31

    reserved = {
      lower_half = "10.0.0.0/31"
      upper_half = "10.0.0.2/31"
    }
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      "/30" = []
      "/31" = []
    })
    error_message = "Touching non-overlapping reserved must not create a false free segment between adjacent blocks."
  }
}

run "next_free_suggestions_respect_configurable_count_per_size" {
  command = plan

  variables {
    base_cidr     = "10.0.0.0/28"
    min_prefix    = 30
    max_prefix    = 32
    suggest_count = 3
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      "/30" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 30
          cidr                       = "10.0.0.0/30"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.4"
          size                       = 30
          cidr                       = "10.0.0.4/30"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 4
        },
        {
          cidr_base                  = "10.0.0.8"
          size                       = 30
          cidr                       = "10.0.0.8/30"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 8
        }
      ]
      "/31" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 31
          cidr                       = "10.0.0.0/31"
          reservable_subnet_count    = 8
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.2"
          size                       = 31
          cidr                       = "10.0.0.2/31"
          reservable_subnet_count    = 8
          alignment_skipped_ip_count = 2
        },
        {
          cidr_base                  = "10.0.0.4"
          size                       = 31
          cidr                       = "10.0.0.4/31"
          reservable_subnet_count    = 8
          alignment_skipped_ip_count = 4
        }
      ]
      "/32" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 32
          cidr                       = "10.0.0.0/32"
          reservable_subnet_count    = 16
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.1"
          size                       = 32
          cidr                       = "10.0.0.1/32"
          reservable_subnet_count    = 16
          alignment_skipped_ip_count = 1
        },
        {
          cidr_base                  = "10.0.0.2"
          size                       = 32
          cidr                       = "10.0.0.2/32"
          reservable_subnet_count    = 16
          alignment_skipped_ip_count = 2
        }
      ]
    })
    error_message = "suggest_count must cap and order next-free suggestions per size deterministically."
  }

  assert {
    condition = jsonencode(output.next_free_cidr) == jsonencode({
      "/30" = {
        cidr_base                  = "10.0.0.0"
        size                       = 30
        cidr                       = "10.0.0.0/30"
        reservable_subnet_count    = 4
        alignment_skipped_ip_count = 0
      }
      "/31" = {
        cidr_base                  = "10.0.0.0"
        size                       = 31
        cidr                       = "10.0.0.0/31"
        reservable_subnet_count    = 8
        alignment_skipped_ip_count = 0
      }
      "/32" = {
        cidr_base                  = "10.0.0.0"
        size                       = 32
        cidr                       = "10.0.0.0/32"
        reservable_subnet_count    = 16
        alignment_skipped_ip_count = 0
      }
    })
    error_message = "next_free must remain first-only even when suggest_count returns multiple candidates in next_free_cidrs."
  }
}
