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
      output.zzz_graph.bucket_count == 64 &&
      output.zzz_graph.bucket_size_ips == 4 &&
      output.zzz_graph.heatmap == join("", [for i in range(64) : " "])
    )
    error_message = "Without reservations in a /24 base, the heatmap must have 64 free buckets (' ') with zero reserved ratio."
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
      output.zzz_graph.bucket_count == 64 &&
      output.zzz_graph.bucket_size_ips == 4 &&
      output.zzz_graph.heatmap == format("%s%s", join("", [for i in range(32) : "#"]), join("", [for i in range(32) : " "]))
    )
    error_message = "With the first /25 reserved in a /24 base, the heatmap must show 32 full buckets ('#') then 32 free buckets (' ')."
  }
}
