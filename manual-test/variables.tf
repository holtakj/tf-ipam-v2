variable "base_cidr" {
  description = "Base IPv4 CIDR block to test."
  type        = string
}

variable "min_prefix" {
  description = "Broadest prefix length to calculate."
  type        = number
}

variable "max_prefix" {
  description = "Narrowest prefix length to calculate."
  type        = number
}

variable "reserved" {
  description = "Reservations to exclude, keyed by name."
  type        = map(string)
}

variable "suggest_count" {
  description = "Number of free subnet suggestions per prefix."
  type        = number
}