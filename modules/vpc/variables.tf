variable "project" {
  type        = string
  description = "Short project name used in resource names."
}

variable "environment" {
  type        = string
  description = "Environment name, e.g. dev or prod."
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR. Subnets are carved as /24s from it."
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR."
  }
}

variable "az_count" {
  type        = number
  description = "How many Availability Zones to spread subnets across."
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "nat_per_az" {
  type        = bool
  description = "One NAT gateway per AZ (HA, higher cost) instead of a single shared one."
  default     = false
}
