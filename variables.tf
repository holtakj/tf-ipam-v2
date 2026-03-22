variable "base_cidr" {
  description = "Base IPv4 CIDR block for IPAM allocations (for example: 10.0.0.0/16)."
  type        = string

  validation {
    condition = (
      length(var.base_cidr) > 0 &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.base_cidr)) &&
      can(cidrnetmask(var.base_cidr)) &&
      try(var.base_cidr == format("%s/%d", cidrhost(var.base_cidr, 0), tonumber(split("/", var.base_cidr)[1])), false)
    )
    error_message = "The 'base_cidr' variable must be a non-empty canonical IPv4 CIDR string (for example: 10.0.0.0/16). IPv6 is not supported. Leading or trailing whitespace is not allowed."
  }
}

variable "min_prefix" {
  description = "Minimum prefix length (broadest/largest network) supported for computation and reserved CIDRs. Networks broader than this (lower prefix number) are not computed. Defaults to 8, meaning /8 is the largest supported network."
  type        = number
  default     = 8

  validation {
    condition     = var.min_prefix >= 8 && var.min_prefix <= 32 && floor(var.min_prefix) == var.min_prefix
    error_message = "The 'min_prefix' variable must be an integer from 8 to 32."
  }
}

variable "max_prefix" {
  description = "Maximum prefix length (narrowest/smallest network) supported for computation and reserved CIDRs. Networks narrower than this (higher prefix number) are not computed. Defaults to 32, meaning /32 host routes are also supported."
  type        = number
  default     = 32

  validation {
    condition     = var.max_prefix >= 8 && var.max_prefix <= 32 && floor(var.max_prefix) == var.max_prefix
    error_message = "The 'max_prefix' variable must be an integer from 8 to 32."
  }
}

variable "reserved" {
  description = "Stable reservation map keyed by reservation name. Reservation names must be unique."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for reservation_name, reservation_cidr in var.reserved :
      length(reservation_name) > 0 &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", reservation_cidr)) &&
      can(cidrnetmask(reservation_cidr)) &&
      try(reservation_cidr == format("%s/%d", cidrhost(reservation_cidr, 0), tonumber(split("/", reservation_cidr)[1])), false)
    ])
    error_message = "Each reserved entry must have a non-empty key and a valid canonical IPv4 CIDR value (host bits must be zero, e.g. 10.0.0.0/24 not 10.0.0.1/24). IPv6 is not supported."
  }
}

variable "suggest_count" {
  description = "How many next-free CIDR suggestions to return per prefix length."
  type        = number
  default     = 1

  validation {
    condition     = var.suggest_count >= 1 && var.suggest_count <= 1024 && floor(var.suggest_count) == var.suggest_count
    error_message = "The 'suggest_count' variable must be an integer from 1 to 1024."
  }
}

