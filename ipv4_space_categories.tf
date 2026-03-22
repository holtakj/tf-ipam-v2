locals {
  ipv4_space_categories = {
    private_use = {
      description = "RFC 1918 private-use space"
      subnets     = true
      cidrs = [
        "10.0.0.0/8",
        "172.16.0.0/12",
        "192.168.0.0/16"
      ]
    }

    carrier_grade_nat = {
      description = "Shared address space for CGNAT (RFC 6598)"
      subnets     = true
      cidrs = [
        "100.64.0.0/10"
      ]
    }

    loopback = {
      description = "Loopback addresses"
      subnets     = false
      cidrs = [
        "127.0.0.0/8"
      ]
    }

    link_local = {
      description = "Link-local autoconfiguration space"
      subnets     = false
      cidrs = [
        "169.254.0.0/16"
      ]
    }

    multicast = {
      description = "Multicast address space"
      subnets     = false
      cidrs = [
        "224.0.0.0/4"
      ]
    }

    reserved_future = {
      description = "Reserved for future use"
      subnets     = false
      cidrs = [
        "240.0.0.0/4"
      ]
    }

    documentation = {
      description = "Documentation and example networks"
      subnets     = false
      cidrs = [
        "192.0.2.0/24",
        "198.51.100.0/24",
        "203.0.113.0/24"
      ]
    }

    benchmarking = {
      description = "Benchmarking tests (RFC 2544)"
      subnets     = false
      cidrs = [
        "198.18.0.0/15"
      ]
    }

    protocol_assignments = {
      description = "IETF protocol assignments"
      subnets     = false
      cidrs = [
        "192.0.0.0/24"
      ]
    }

    this_network = {
      description = "This host on this network"
      subnets     = false
      cidrs = [
        "0.0.0.0/8"
      ]
    }

    limited_broadcast = {
      description = "Limited broadcast"
      subnets     = false
      cidrs = [
        "255.255.255.255/32"
      ]
    }
  }
}
