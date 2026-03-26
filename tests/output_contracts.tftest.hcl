run "output_contracts_without_reserved" {
  command = plan

  variables {
    base_cidr     = "10.0.0.0/30"
    min_prefix    = 30
    max_prefix    = 32
    suggest_count = 2
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      "/30" = 1
      "/31" = 2
      "/32" = 4
    })
    error_message = "subnet_count must report expected capacity per prefix."
  }

  assert {
    condition     = jsonencode(output.reserved) == jsonencode({})
    error_message = "reserved must echo the reserved input map."
  }

  assert {
    condition = jsonencode(output.subnet_usage_by_size) == jsonencode({
      "/30" = {
        reservable_subnet_count    = 1
        reserved_subnet_count      = 0
        reserved_subnet_percentage = 0
      }
      "/31" = {
        reservable_subnet_count    = 2
        reserved_subnet_count      = 0
        reserved_subnet_percentage = 0
      }
      "/32" = {
        reservable_subnet_count    = 4
        reserved_subnet_count      = 0
        reserved_subnet_percentage = 0
      }
    })
    error_message = "subnet_usage_by_size must report reservable/reserved counts and percentages for each prefix."
  }

  assert {
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      "/30" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 30
          cidr                       = "10.0.0.0/30"
          reservable_subnet_count    = 1
          alignment_skipped_ip_count = 0
        }
      ]
      "/31" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 31
          cidr                       = "10.0.0.0/31"
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.2"
          size                       = 31
          cidr                       = "10.0.0.2/31"
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 2
        }
      ]
      "/32" = [
        {
          cidr_base                  = "10.0.0.0"
          size                       = 32
          cidr                       = "10.0.0.0/32"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.1"
          size                       = 32
          cidr                       = "10.0.0.1/32"
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 1
        }
      ]
    })
    error_message = "next_free_cidrs must return up to suggest_count suggestions per prefix."
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
    error_message = "next_free_cidr must expose exactly the first suggestion per prefix."
  }

  assert {
    condition = alltrue([
      for cidr_key, suggestions in output.next_free_cidrs :
      jsonencode(output.next_free_cidr[cidr_key]) == jsonencode(try(suggestions[0], null))
    ])
    error_message = "next_free_cidr must be equivalent to the first element of next_free_cidrs for every prefix key."
  }
}

run "output_contracts_when_no_capacity_left" {
  command = plan

  variables {
    base_cidr     = "10.0.0.0/30"
    min_prefix    = 30
    max_prefix    = 31
    suggest_count = 3

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
    error_message = "next_free_cidrs must be empty lists when no allocatable subnets remain."
  }

  assert {
    condition = jsonencode(output.next_free_cidr) == jsonencode({
      "/30" = null
      "/31" = null
    })
    error_message = "next_free_cidr must be null when no suggestion is available."
  }

  assert {
    condition = jsonencode(output.subnet_usage_by_size) == jsonencode({
      "/30" = {
        reservable_subnet_count    = 0
        reserved_subnet_count      = 1
        reserved_subnet_percentage = 100
      }
      "/31" = {
        reservable_subnet_count    = 0
        reserved_subnet_count      = 2
        reserved_subnet_percentage = 100
      }
    })
    error_message = "subnet_usage_by_size must report full reservation (100%) when no capacity remains."
  }

  assert {
    condition = alltrue([
      for cidr_key, suggestions in output.next_free_cidrs :
      jsonencode(output.next_free_cidr[cidr_key]) == jsonencode(try(suggestions[0], null))
    ])
    error_message = "next_free_cidr must remain consistent with next_free_cidrs even when all entries are empty."
  }

  assert {
    condition = jsonencode(output.reserved) == jsonencode({
      lower_half = "10.0.0.0/31"
      upper_half = "10.0.0.2/31"
    })
    error_message = "reserved must echo the reservation name-to-cidr map."
  }
}
