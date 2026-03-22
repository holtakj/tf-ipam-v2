run "base_10_0_0_0_16_with_single_mid_24_gap_suggests_that_24" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/16"
    min_prefix = 16
    max_prefix = 32

    # Reserve all /26 blocks in the /16 except the four that make 10.0.128.0/24.
    # /24 10.0.128.0 maps to /26 indices 512..515.
    reserved = {
      for i in range(1024) :
      format("r%04d", i) => cidrsubnet("10.0.0.0/16", 10, i)
      if i < 512 || i > 515
    }
  }

  assert {
    condition = (
      length(output.next_free["/24"]) > 0 &&
      output.next_free["/24"][0].cidr == "10.0.128.0/24" &&
      output.next_free["/24"][0].reservable_subnet_count == 1 &&
      output.next_free["/24"][0].alignment_skipped_ip_count == 0 &&
      output.next_free["/23"] == [] &&
      output.next_free["/26"][0].cidr == "10.0.128.0/26" &&
      output.next_free["/26"][0].reservable_subnet_count == 4
    )
    error_message = "With one mid /24 gap in an otherwise fully reserved /16, the module must suggest that exact /24 as next free and report exactly one reservable /24."
  }
}
