run "base_10_0_0_0_16_with_1024_contiguous_reservations_has_no_free_24" {
  command = plan

  variables {
    base_network_cidr = "10.0.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 32

    # 1024 contiguous /26 reservations exactly tile the /16 without gaps.
    reservations = {
      for i in range(1024) :
      format("r%04d", i) => cidrsubnet("10.0.0.0/16", 10, i)
    }
  }

  assert {
    condition = (
      output.free_cidr_suggestions["/24"] == null &&
      output.subnet_count_by_cidr_size["/24"] == 256 &&
      output.free_cidr_suggestions["/26"] == null &&
      output.free_cidr_suggestions["/32"] == null
    )
    error_message = "With 1024 contiguous /26 reservations covering the full /16, there must be no free /24 (or any smaller subnet) left to reserve."
  }
}
