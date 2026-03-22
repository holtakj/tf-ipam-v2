# Pseudo-random k8s-style CIDR splicing tests.
# Pattern: split a /16 into node, pod, and service networks across multiple clusters.

run "k8s_multi_cluster_randomized_layout_a" {
  command = plan

  variables {
    base_network_cidr = "10.42.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      c1_nodes = "10.42.0.0/20"
      c1_pods  = "10.42.64.0/18"
      c1_svc   = "10.42.16.0/24"

      c2_nodes = "10.42.32.0/20"
      c2_pods  = "10.42.128.0/18"
      c2_svc   = "10.42.48.0/24"
    }
  }

  assert {
    condition = (
      output.free_cidr_suggestions["/18"][0].cidr == "10.42.192.0/18" &&
      output.free_cidr_suggestions["/20"][0].cidr == "10.42.192.0/20" &&
      output.free_cidr_suggestions["/24"][0].cidr == "10.42.17.0/24"
    )
    error_message = "The next free /18, /20, and /24 should point to the first aligned non-overlapping gaps in this randomized k8s layout."
  }
}

run "k8s_multi_cluster_randomized_layout_b" {
  command = plan

  variables {
    base_network_cidr = "10.60.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      a_pod   = "10.60.0.0/17"
      b_pod   = "10.60.128.0/18"
      a_nodes = "10.60.192.0/20"
      b_nodes = "10.60.208.0/20"
      a_svc   = "10.60.224.0/24"
      b_svc   = "10.60.225.0/24"
    }
  }

  assert {
    condition = (
      output.free_cidr_suggestions["/18"] == [] &&
      output.free_cidr_suggestions["/20"][0].cidr == "10.60.240.0/20" &&
      output.free_cidr_suggestions["/20"][0].reservable_subnet_count == 1 &&
      output.free_cidr_suggestions["/24"][0].cidr == "10.60.226.0/24"
    )
    error_message = "When pods consume most of the /16, /18 can be exhausted while /20 and /24 still have a deterministic next free slot."
  }
}

run "k8s_multi_cluster_randomized_layout_c" {
  command = plan

  variables {
    base_network_cidr = "10.70.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      c1_pod   = "10.70.0.0/18"
      c1_nodes = "10.70.64.0/20"
      c1_svc   = "10.70.80.0/24"
      c2_pod   = "10.70.128.0/17"
    }
  }

  assert {
    condition = (
      output.free_cidr_suggestions["/18"] == [] &&
      output.free_cidr_suggestions["/20"][0].cidr == "10.70.96.0/20" &&
      output.free_cidr_suggestions["/20"][0].reservable_subnet_count == 2 &&
      output.free_cidr_suggestions["/24"][0].cidr == "10.70.81.0/24"
    )
    error_message = "Randomized cluster block placement should preserve first-fit behavior for /20 and /24 while /18 remains exhausted."
  }
}

run "k8s_randomized_overlap_between_cluster_ranges_fails" {
  command = plan

  variables {
    base_network_cidr = "10.80.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      c1_nodes = "10.80.32.0/20"
      c1_pods  = "10.80.32.0/19"
      c1_svc   = "10.80.48.0/24"
    }
  }

  expect_failures = [
    output.reserved,
  ]
}

run "k8s_randomized_out_of_base_cluster_range_fails" {
  command = plan

  variables {
    base_network_cidr = "10.90.0.0/16"
    min_prefix_length = 16
    max_prefix_length = 24

    reservations = {
      c1_nodes = "10.90.32.0/20"
      c1_pods  = "10.91.0.0/17"
      c1_svc   = "10.90.48.0/24"
    }
  }

  expect_failures = [
    output.reserved,
  ]
}
