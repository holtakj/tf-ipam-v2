# Tests that exercise a mix of canonical IPv4 CIDR and IP range reservations
# in the same reserved map, verifying free-space computation, overlap detection,
# and full-coverage edge cases.

# ──────────────────────────────────────────────────────────────────────────────
# T1: alternating CIDR / range / CIDR in a /16 leaves three free islands
#
# Layout (each entry = one /24 slot):
#   index 0  : 10.0.0.0/24   — CIDR reservation
#   index 1  : free           → first free /24
#   index 2  : 10.0.2.0-..255 — IP range reservation
#   index 3  : free           → second free /24
#   index 4  : 10.0.4.0/24   — CIDR reservation
#   index 5+ : free           → third (and beyond) free /24
#   → first free /23: indices 6-7 (10.0.6.0/23) — first two-slot gap
# ──────────────────────────────────────────────────────────────────────────────
run "alternating_cidr_range_cidr_in_16_leaves_three_free_24s" {
  command = plan

  variables {
    base_cidr     = "10.0.0.0/16"
    min_prefix    = 16
    max_prefix    = 24
    suggest_count = 3

    reserved = {
      "head-cidr" = "10.0.0.0/24"
      "mid-range" = "10.0.2.0-10.0.2.255"
      "tail-cidr" = "10.0.4.0/24"
    }
  }

  assert {
    condition = (
      length(output.next_free_cidrs["/24"]) == 3 &&
      output.next_free_cidrs["/24"][0].cidr == "10.0.1.0/24" &&
      output.next_free_cidrs["/24"][1].cidr == "10.0.3.0/24" &&
      output.next_free_cidrs["/24"][2].cidr == "10.0.5.0/24" &&
      output.next_free_cidrs["/24"][0].reservable_subnet_count == 253
    )
    error_message = "Alternating CIDR/range/CIDR reservations must expose exactly three free /24 islands and report 253 reservable /24 blocks."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# T2: a CIDR and an IP range that overlap must fail the non-overlap precondition
#
#   10.0.0.0/25  → covers 10.0.0.0–10.0.0.127
#   10.0.0.64-10.0.0.191 → overlaps at 10.0.0.64–10.0.0.127
# ──────────────────────────────────────────────────────────────────────────────
run "overlapping_cidr_and_range_fails_non_overlap_precondition" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32

    reserved = {
      "cidr-block"  = "10.0.0.0/25"
      "range-block" = "10.0.0.64-10.0.0.191"
    }
  }

  expect_failures = [output.reserved]
}

# ──────────────────────────────────────────────────────────────────────────────
# T3: a CIDR followed immediately by a touching range covers the full /24
#
#   10.0.0.0/25  → 10.0.0.0–10.0.0.127
#   10.0.0.128-10.0.0.255 → fills the rest
#   → no free space at any prefix
# ──────────────────────────────────────────────────────────────────────────────
run "touching_cidr_and_range_cover_full_24_leaves_no_free_space" {
  command = plan

  variables {
    base_cidr  = "10.0.0.0/24"
    min_prefix = 24
    max_prefix = 32

    reserved = {
      "first-half-cidr"   = "10.0.0.0/25"
      "second-half-range" = "10.0.0.128-10.0.0.255"
    }
  }

  assert {
    condition = (
      output.next_free_cidrs["/24"] == [] &&
      output.next_free_cidrs["/25"] == [] &&
      output.next_free_cidrs["/32"] == []
    )
    error_message = "Touching CIDR + range covering the entire /24 must leave no free subnets at any prefix length."
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# T4: range in the middle, CIDRs at each edge — three free /27 fragments
#
#   10.0.0.0/27   → offsets   0– 31  (CIDR)
#   10.0.0.64-127 → offsets  64–127  (range)
#   10.0.0.192/26 → offsets 192–255  (CIDR)
#   free:
#     32– 63  one  /27: 10.0.0.32/27
#    128–191  two /27s: 10.0.0.128/27, 10.0.0.160/27
#   first free /28: 10.0.0.32/28  — reservable /28 count: 6
# ──────────────────────────────────────────────────────────────────────────────
run "range_middle_cidr_edges_yields_three_free_27_fragments" {
  command = plan

  variables {
    base_cidr     = "10.0.0.0/24"
    min_prefix    = 24
    max_prefix    = 32
    suggest_count = 3

    reserved = {
      "left-edge-cidr"  = "10.0.0.0/27"
      "middle-range"    = "10.0.0.64-10.0.0.127"
      "right-edge-cidr" = "10.0.0.192/26"
    }
  }

  assert {
    condition = (
      length(output.next_free_cidrs["/27"]) == 3 &&
      output.next_free_cidrs["/27"][0].cidr == "10.0.0.32/27" &&
      output.next_free_cidrs["/27"][1].cidr == "10.0.0.128/27" &&
      output.next_free_cidrs["/27"][2].cidr == "10.0.0.160/27" &&
      output.next_free_cidrs["/27"][0].reservable_subnet_count == 3 &&
      output.next_free_cidrs["/28"][0].cidr == "10.0.0.32/28" &&
      output.next_free_cidrs["/28"][0].reservable_subnet_count == 6
    )
    error_message = "With left/right CIDR edges and a range in the middle, exactly three /27 fragments must be free, and first free /28 must be 10.0.0.32/28 with 6 total reservable /28 blocks."
  }
}
