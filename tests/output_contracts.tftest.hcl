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
    condition = jsonencode(output.next_free_cidrs) == jsonencode({
      "/30" = [
        {
          cidr_base                  = "10.0.0.0"
          cidr_size                  = 30
          cidr                       = "10.0.0.0/30"
          cidr_ip_count              = 4
          reservable_subnet_count    = 1
          alignment_skipped_ip_count = 0
        }
      ]
      "/31" = [
        {
          cidr_base                  = "10.0.0.0"
          cidr_size                  = 31
          cidr                       = "10.0.0.0/31"
          cidr_ip_count              = 2
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.2"
          cidr_size                  = 31
          cidr                       = "10.0.0.2/31"
          cidr_ip_count              = 2
          reservable_subnet_count    = 2
          alignment_skipped_ip_count = 2
        }
      ]
      "/32" = [
        {
          cidr_base                  = "10.0.0.0"
          cidr_size                  = 32
          cidr                       = "10.0.0.0/32"
          cidr_ip_count              = 1
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 0
        },
        {
          cidr_base                  = "10.0.0.1"
          cidr_size                  = 32
          cidr                       = "10.0.0.1/32"
          cidr_ip_count              = 1
          reservable_subnet_count    = 4
          alignment_skipped_ip_count = 1
        }
      ]
    })
    error_message = "next_free_cidrs must return up to suggest_count suggestions per prefix."
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
    condition = jsonencode(output.reserved) == jsonencode({
      lower_half = "10.0.0.0/31"
      upper_half = "10.0.0.2/31"
    })
    error_message = "reserved must echo the reservation name-to-cidr map."
  }
}
