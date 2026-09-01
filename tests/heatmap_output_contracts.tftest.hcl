run "heatmap_without_reservations_is_all_free" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32
  }

  assert {
    condition = (
      output.zzz_graph.base_cidr == "10.0.0.0/24" &&
        output.zzz_graph.total_ip_count == 256 &&
        output.zzz_graph.ips_per_dot == 1 &&
        output.zzz_graph.usage_percent == 0 &&
        output.zzz_graph.heatmap == format("\n%-15s|%s| %-15s\n", "10.0.0.0", join("", [for i in range(32) : "⠀"]), "10.0.0.255")
    )
      error_message = "Without reservations in a /24 base, the heatmap must have 32 empty Braille characters."
  }
}

run "heatmap_half_reserved_in_24_is_half_full_buckets" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32

    # Reserve exactly half of the /24: 128 IPs.
    reserved = {
      half = "10.0.0.0/25"
    }
  }

  assert {
    condition = (
      output.zzz_graph.total_ip_count == 256 &&
      output.zzz_graph.ips_per_dot == 1 &&
      output.zzz_graph.usage_percent == 50 &&
      output.zzz_graph.heatmap == format("\n%-15s|%s%s| %-15s\n", "10.0.0.0", join("", [for i in range(16) : "⣿"]), join("", [for i in range(16) : "⠀"]), "10.0.0.255")
    )
     error_message = "With the first /25 reserved in a /24 base, the heatmap must show 16 full Braille characters then 16 empty ones."
  }
}

run "heatmap_uses_one_ip_per_dot_in_23" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/23"
    min_prefix = 23
    max_prefix = 32

    reserved = {
      first_dot = "10.0.0.0-10.0.0.0"
    }
  }

  assert {
    condition = (
      output.zzz_graph.total_ip_count == 512 &&
      output.zzz_graph.ips_per_dot == 1 &&
      output.zzz_graph.usage_percent == 0.19531 &&
      output.zzz_graph.heatmap == format("\n%-15s|%s%s| %-15s\n", "10.0.0.0", "⡀", join("", [for i in range(63) : "⠀"]), "10.0.1.255")
    )
    error_message = "A /23 heatmap must assign one IP per Braille dot, starting at the bottom-left dot."
  }
}

run "heatmap_uses_one_ip_per_dot_in_21" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/21"
    min_prefix = 21
    max_prefix = 32

    reserved = {
      first_dot = "10.0.0.0-10.0.0.0"
    }
  }

  assert {
    condition = (
      output.zzz_graph.total_ip_count == 2048 &&
      output.zzz_graph.ips_per_dot == 1 &&
      output.zzz_graph.heatmap == format("\n%-15s|%s%s| %-15s\n%-15s|%s| %-15s\n%-15s|%s| %-15s\n%-15s|%s| %-15s\n", "10.0.0.0", "⡀", join("", [for i in range(63) : "⠀"]), "10.0.1.255", "10.0.2.0", join("", [for i in range(64) : "⠀"]), "10.0.3.255", "10.0.4.0", join("", [for i in range(64) : "⠀"]), "10.0.5.255", "10.0.6.0", join("", [for i in range(64) : "⠀"]), "10.0.7.255")
    )
    error_message = "A /21 heatmap must assign one IP per Braille dot across four 64-character rows."
  }
}

run "heatmap_scales_ips_per_dot_above_18" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 32
  }

  assert {
    condition     = output.zzz_graph.ips_per_dot == 4
    error_message = "A /16 heatmap must use 4 IPs per dot to stay within the 16,384-dot limit."
  }
}

run "heatmap_scales_ips_per_dot_in_15" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/15"
    min_prefix = 15
    max_prefix = 32
  }

  assert {
    condition     = output.zzz_graph.ips_per_dot == 8
    error_message = "A /15 heatmap must use 8 IPs per dot to stay within the 16,384-dot limit."
  }
}
