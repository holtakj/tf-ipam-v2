locals {

  reserved_cidrs = values(var.reserved)

  # Reservation names are metadata only; uniqueness is enforced on CIDR values.
  reserved_cidrs_unique = length(distinct(local.reserved_cidrs)) == length(local.reserved_cidrs)

  # validatefx::cidr_overlap throws on overlap; can(...) turns that into a boolean check result.
  reserved_cidrs_non_overlapping = can(provider::validatefx::cidr_overlap(local.reserved_cidrs))


  # Parse the base prefix once.
  base_prefix_length  = tonumber(split("/", var.base_cidr)[1])
  computation_enabled = local.base_prefix_length <= var.max_prefix

  # Convert the base CIDR boundaries to integers so we can do interval math.
  # Formula: a.b.c.d => a*256^3 + b*256^2 + c*256 + d.
  base_start_int = (
    tonumber(split(".", cidrhost(var.base_cidr, 0))[0]) * 16777216 +
    tonumber(split(".", cidrhost(var.base_cidr, 0))[1]) * 65536 +
    tonumber(split(".", cidrhost(var.base_cidr, 0))[2]) * 256 +
    tonumber(split(".", cidrhost(var.base_cidr, 0))[3])
  )

  # The base range is inclusive, so subtract 1 from subnet size to get the ending address.
  # subnet_size(base) = 2^(32-prefix).
  base_end_int = local.base_start_int + pow(2, 32 - local.base_prefix_length) - 1

  # Reuse a single scoped size list so downstream maps only materialize returned CIDR sizes.
  scoped_cidr_sizes = range(var.min_prefix, var.max_prefix + 1)

  # Taxative count map for each requested size inside the base CIDR window.
  # For sizes outside [base_prefix_length, max_prefix], count is forced to 0.
  subnet_count = {
    for cidr_size in local.scoped_cidr_sizes :
    format("/%d", cidr_size) => (
      cidr_size < local.base_prefix_length ? 0 : pow(2, cidr_size - local.base_prefix_length)
    )
  }

  # Normalize reservation CIDRs and precompute numeric range boundaries.
  # canonical_cidr enforces host-bit normalization (e.g. 10.0.0.1/24 -> 10.0.0.0/24).
  # subnet_size is later reused to validate alignment against the base start offset.
  reserved_ranges = [
    for cidr in local.reserved_cidrs : {
      cidr           = cidr
      prefix_length  = tonumber(split("/", cidr)[1])
      canonical_cidr = format("%s/%d", cidrhost(cidr, 0), tonumber(split("/", cidr)[1]))
      subnet_size    = pow(2, 32 - tonumber(split("/", cidr)[1]))
      start_int = (
        tonumber(split(".", cidrhost(cidr, 0))[0]) * 16777216 +
        tonumber(split(".", cidrhost(cidr, 0))[1]) * 65536 +
        tonumber(split(".", cidrhost(cidr, 0))[2]) * 256 +
        tonumber(split(".", cidrhost(cidr, 0))[3])
      )
      end_int = (
        tonumber(split(".", cidrhost(cidr, 0))[0]) * 16777216 +
        tonumber(split(".", cidrhost(cidr, 0))[1]) * 65536 +
        tonumber(split(".", cidrhost(cidr, 0))[2]) * 256 +
        tonumber(split(".", cidrhost(cidr, 0))[3]) +
        pow(2, 32 - tonumber(split("/", cidr)[1])) -
        1
      )
    }
  ]

  # Validate each reservation is canonical, aligned, in-range, and enabled by current prefix bounds.
  # Alignment rule: (reservation_start - base_start) mod reservation_size == 0.
  # This guarantees the reservation is on a valid subnet boundary relative to base_cidr.
  reserved_cidrs_exist = alltrue([
    for reserved_range in local.reserved_ranges : (
      local.computation_enabled &&
      reserved_range.cidr == reserved_range.canonical_cidr &&
      reserved_range.prefix_length >= var.min_prefix &&
      reserved_range.prefix_length <= var.max_prefix &&
      reserved_range.prefix_length >= local.base_prefix_length &&
      reserved_range.start_int >= local.base_start_int &&
      reserved_range.end_int <= local.base_end_int &&
      (reserved_range.start_int - local.base_start_int) % reserved_range.subnet_size == 0
    )
  ])



  # Intersect reservation ranges with the base range so later logic only sees relevant blockers.
  # Although checks already constrain reserved, intersection keeps this stage defensive and local.
  blocking_reserved_ranges = [
    for reserved_range in local.reserved_ranges : {
      start_int = max(local.base_start_int, reserved_range.start_int)
      end_int   = min(local.base_end_int, reserved_range.end_int)
    }
    if max(local.base_start_int, reserved_range.start_int) <= min(local.base_end_int, reserved_range.end_int)
  ]

  # Keep blockers ordered by start boundary to derive free segments deterministically.
  # We sort a stable key "start:index" and then rehydrate original objects by index.
  # This avoids relying on object sort behavior and handles equal-start ranges safely.
  sorted_blocking_range_indices = [
    for sortable in sort([
      for index, blocking_range in local.blocking_reserved_ranges :
      format("%012.0f:%06d", blocking_range.start_int, index)
    ]) : tonumber(split(":", sortable)[1])
  ]

  sorted_blocking_ranges = [
    for index in local.sorted_blocking_range_indices : local.blocking_reserved_ranges[index]
  ]

  # Build contiguous free IP segments: head gap, internal gaps, and tail gap.
  # Output invariant: free_ip_segments is a disjoint, ordered list of inclusive [start_int, end_int].
  # Cases handled:
  # 1) no blockers => one segment spanning entire base
  # 2) head gap before first blocker
  # 3) gap between each adjacent blocker pair
  # 4) tail gap after last blocker
  free_ip_segments = !local.computation_enabled ? [] : concat(
    length(local.sorted_blocking_ranges) == 0 ? [{
      start_int = local.base_start_int
      end_int   = local.base_end_int
    }] : [],
    length(local.sorted_blocking_ranges) > 0 ? (local.base_start_int < local.sorted_blocking_ranges[0].start_int ? [{
      start_int = local.base_start_int
      end_int   = local.sorted_blocking_ranges[0].start_int - 1
    }] : []) : [],
    [
      for index in range(length(local.sorted_blocking_ranges) > 0 ? length(local.sorted_blocking_ranges) - 1 : 0) : {
        start_int = local.sorted_blocking_ranges[index].end_int + 1
        end_int   = local.sorted_blocking_ranges[index + 1].start_int - 1
      }
      if local.sorted_blocking_ranges[index].end_int + 1 <= local.sorted_blocking_ranges[index + 1].start_int - 1
    ],
    length(local.sorted_blocking_ranges) > 0 ? (local.sorted_blocking_ranges[length(local.sorted_blocking_ranges) - 1].end_int < local.base_end_int ? [{
      start_int = local.sorted_blocking_ranges[length(local.sorted_blocking_ranges) - 1].end_int + 1
      end_int   = local.base_end_int
    }] : []) : []
  )

  # For every CIDR size, compute free subnet index intervals [first,last] inside each free segment.
  # Indexing model for a given cidr_size:
  # - subnet_size = 2^(32-cidr_size)
  # - subnet index 0 starts at base_start_int
  # - subnet index i starts at base_start_int + i*subnet_size
  #
  # Given a free segment [S,E], valid indices are:
  # - first = ceil((S - base_start) / subnet_size)
  # - last  = floor((E - subnet_size + 1 - base_start) / subnet_size)
  #
  # We keep only intervals where first <= last.
  free_subnet_index_ranges_by_size = {
    for cidr_size in local.scoped_cidr_sizes : cidr_size => (
      !local.computation_enabled || cidr_size < local.base_prefix_length ? [] : [
        for free_segment in local.free_ip_segments : {
          first = ceil((free_segment.start_int - local.base_start_int) / pow(2, 32 - cidr_size))
          last  = floor((free_segment.end_int - pow(2, 32 - cidr_size) + 1 - local.base_start_int) / pow(2, 32 - cidr_size))
        }
        if ceil((free_segment.start_int - local.base_start_int) / pow(2, 32 - cidr_size)) <= floor((free_segment.end_int - pow(2, 32 - cidr_size) + 1 - local.base_start_int) / pow(2, 32 - cidr_size))
      ]
    )
  }

  # Collapse index intervals to a per-size count of reservable aligned subnets.
  # Each interval contributes (last-first+1) aligned subnets.
  reservable_subnet_count_by_size = {
    for cidr_size in local.scoped_cidr_sizes : cidr_size => (
      length(local.free_subnet_index_ranges_by_size[cidr_size]) > 0
      ? sum([
        for free_range in local.free_subnet_index_ranges_by_size[cidr_size] :
        free_range.last - free_range.first + 1
      ])
      : 0
    )
  }

  # Build candidate indices per CIDR size from each free interval.
  # We keep at most suggest_count indices per interval, then slice globally per size.
  candidate_free_subnet_indices_by_size = {
    for cidr_size in local.scoped_cidr_sizes : cidr_size => (
      !local.computation_enabled || cidr_size < local.base_prefix_length ? [] : flatten([
        for free_range in local.free_subnet_index_ranges_by_size[cidr_size] : [
          for offset in range(min(var.suggest_count, free_range.last - free_range.first + 1)) :
          free_range.first + offset
        ]
      ])
    )
  }

  selected_free_subnet_indices_by_size = {
    for cidr_size in local.scoped_cidr_sizes : cidr_size => (
      slice(
        local.candidate_free_subnet_indices_by_size[cidr_size],
        0,
        min(var.suggest_count, length(local.candidate_free_subnet_indices_by_size[cidr_size]))
      )
    )
  }

  # Emit next-free suggestions for sizes within scope (min_prefix.. max_prefix).
  # For each size key, return up to suggest_count allocatable aligned subnets.
  # For every suggestion we emit:
  # - cidr_base/cidr: allocatable aligned subnet
  # - reservable_subnet_count: total allocatable aligned subnets of that size
  # - alignment_skipped_ip_count: number of free IPs that occur before this aligned suggestion
  next_free_cidr_suggestions_by_size = {
    for cidr_size in local.scoped_cidr_sizes :
    format("/%d", cidr_size) => [
      for subnet_index in local.selected_free_subnet_indices_by_size[cidr_size] : {
        cidr_base               = split("/", cidrsubnet(var.base_cidr, cidr_size - local.base_prefix_length, subnet_index))[0]
        size                    = cidr_size
        cidr                    = cidrsubnet(var.base_cidr, cidr_size - local.base_prefix_length, subnet_index)
        reservable_subnet_count = local.reservable_subnet_count_by_size[cidr_size]
        alignment_skipped_ip_count = sum([
          for free_segment in local.free_ip_segments : max(
            0,
            min(free_segment.end_int, (local.base_start_int + (subnet_index * pow(2, 32 - cidr_size))) - 1) - free_segment.start_int + 1
          )
        ])
      }
    ]
  }

  # Derived single-suggestion view: first suggestion per size or null when unavailable.
  next_free_cidr_suggestion_by_size = {
    for cidr_size, suggestions in local.next_free_cidr_suggestions_by_size :
    cidr_size => try(suggestions[0], null)
  }
}

