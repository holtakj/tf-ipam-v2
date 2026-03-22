run "base_10_0_0_0_16_with_1024_contiguous_reservations_has_no_free_24" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 32

    # 1024 contiguous /26 reserved exactly tile the /16 without gaps.
    reserved = {
      for i in range(1024) :
      format("r%04d", i) => cidrsubnet("10.0.0.0/16", 10, i)
    }
  }

  assert {
    condition = (
      output.next_free_cidrs["/24"] == [] &&
      output.subnet_count["/24"] == 256 &&
      output.next_free_cidrs["/26"] == [] &&
      output.next_free_cidrs["/32"] == []
    )
    error_message = "With 1024 contiguous /26 reserved covering the full /16, there must be no free /24 (or any smaller subnet) left to reserve."
  }
}
