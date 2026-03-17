variable "base_network_cidr" {
  description = "Base IPv4 CIDR block for IPAM allocations (for example: 10.0.0.0/16)."
  type        = string

  validation {
    condition = (
      length(var.base_network_cidr) > 0 &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.base_network_cidr)) &&
      can(cidrnetmask(var.base_network_cidr)) &&
      try(var.base_network_cidr == format("%s/%d", cidrhost(var.base_network_cidr, 0), tonumber(split("/", var.base_network_cidr)[1])), false)
    )
    error_message = "The 'base_network_cidr' variable must be a non-empty canonical IPv4 CIDR string (for example: 10.0.0.0/16). IPv6 is not supported. Leading or trailing whitespace is not allowed."
  }
}

variable "min_prefix_length" {
  description = "Minimum prefix length (broadest/largest network) supported for computation and reservations. Networks broader than this (lower prefix number) are not computed. Defaults to 8, meaning /8 is the largest supported network."
  type        = number
  default     = 8

  validation {
    condition     = var.min_prefix_length >= 8 && var.min_prefix_length <= 32 && floor(var.min_prefix_length) == var.min_prefix_length
    error_message = "The 'min_prefix_length' variable must be an integer from 8 to 32."
  }
}

variable "max_prefix_length" {
  description = "Maximum prefix length (narrowest/smallest network) supported for computation and reservations. Networks narrower than this (higher prefix number) are not computed. Defaults to 32, meaning /32 host routes are also supported."
  type        = number
  default     = 32

  validation {
    condition     = var.max_prefix_length >= 8 && var.max_prefix_length <= 32 && floor(var.max_prefix_length) == var.max_prefix_length
    error_message = "The 'max_prefix_length' variable must be an integer from 8 to 32."
  }
}

variable "reservations" {
  description = "Stable reservation map keyed by reservation name. Reservation names must be unique."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for reservation_name, reservation_cidr in var.reservations :
      length(reservation_name) > 0 &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", reservation_cidr)) &&
      can(cidrnetmask(reservation_cidr)) &&
      try(reservation_cidr == format("%s/%d", cidrhost(reservation_cidr, 0), tonumber(split("/", reservation_cidr)[1])), false)
    ])
    error_message = "Each reservations entry must have a non-empty key and a valid canonical IPv4 CIDR value (host bits must be zero, e.g. 10.0.0.0/24 not 10.0.0.1/24). IPv6 is not supported."
  }
}

