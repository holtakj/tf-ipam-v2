locals {
  ipv4_network_classes = {
    class_a = {
      description       = "Class A"
      first_octet_range = "1-126"
      cidr              = "0.0.0.0/1"
      default_prefix    = 8
      subnets           = true
    }

    class_b = {
      description       = "Class B"
      first_octet_range = "128-191"
      cidr              = "128.0.0.0/2"
      default_prefix    = 16
      subnets           = true
    }

    class_c = {
      description       = "Class C"
      first_octet_range = "192-223"
      cidr              = "192.0.0.0/3"
      default_prefix    = 24
      subnets           = true
    }

    class_d = {
      description       = "Class D (Multicast)"
      first_octet_range = "224-239"
      cidr              = "224.0.0.0/4"
      default_prefix    = 32
      subnets           = false
    }

    class_e = {
      description       = "Class E (Reserved)"
      first_octet_range = "240-255"
      cidr              = "240.0.0.0/4"
      default_prefix    = 32
      subnets           = false
    }
  }
}
