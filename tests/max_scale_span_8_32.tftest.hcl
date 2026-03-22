run "maximum_supported_chunked_workload" {
  command = plan

  variables {
    base_cidr = "10.0.0.0/8"
    min_prefix = 8
    max_prefix = 32
  }

  assert {
    condition = jsonencode(output.subnet_count) == jsonencode({
      for cidr_size in range(8, 33) :
      format("/%d", cidr_size) => pow(2, cidr_size - 8)
      }) && jsonencode(output.next_free) == jsonencode({
      for cidr_key, suggestion in merge(
        { for cidr_size in range(8, 33) : format("/%d", cidr_size) => null },
        {
          for cidr_size in range(8, 33) :
          format("/%d", cidr_size) => {
            cidr_base                  = split("/", cidrsubnet("10.0.0.0/8", cidr_size - 8, 0))[0]
            size                       = cidr_size
            cidr                       = cidrsubnet("10.0.0.0/8", cidr_size - 8, 0)
            reservable_subnet_count    = pow(2, cidr_size - 8)
            alignment_skipped_ip_count = 0
          }
        }
      ) : cidr_key => (suggestion == null ? [] : [suggestion])
    })
    error_message = "The module must handle the heaviest supported workload for this /8 base and produce the exact expected count and suggestion maps."
  }
}