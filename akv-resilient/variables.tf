#Authentication/Subscription
variable "client_id" {
  type = string
  default = ""
}
variable "client_secret" {
  type = string
  default = ""
}
variable "tfstate_accesskey" {
  type = string
  default = ""
}
variable "subscription_id" {
  type = string
  default = ""
}
variable "tenant_id" {
  type = string
  default = "b7f604a0-00a9-4188-9248-42f3a5aac2e9"
}

#Environment and Naming
variable "environment" {
  type = string
}

variable "keyvault_name" {
  type = string
  description = "ServiceNow-provided base Key Vault name used to derive resilient regional names."
}

#Regions (multi-region fan out)
variable "regions" {
  description = "Regions to deploy into; keys are Azure region codes."
  type = map(object({
    keyvault_name = string
    role_suffix = string
    kv_resource_group = string
    vnet_name = string
    subnet_name = string
    snet_rg_name = string
  }))

  validation {
    condition = length(var.regions) == 3
    error_message = "Exactly 3 regions are required for resilient deployment (primary, secondary, and DR)."
  }
}

#DNS (central private link DNS Zone)
variable "private_dns_zone_id" {
  type = string
  default = ""
  description = "Full resource ID of privatelink.vaultcore.azure.net. If empty, we will try to data-source by name + RG. "
}

#Group name used in private_dns_zone_group (we’ll default it)
variable "private_dns_zone_group" {
  type    = string
  default = "kv-privatelink"
}


#Back-compat: name & RG to data-source the zone if ID not provided
variable "private_dns_zone_name" {
  type        = string
  default     = "privatelink.vaultcore.azure.net"
  description = "Private DNS zone name for Key Vault Private Link; defaults to privatelink.vaultcore.azure.net."
}
variable "private_dns_zone_rg_name" {
  type        = string
  default     = ""
  description = "Resource group of the Private DNS zone if you prefer data-source discovery."
}

variable "enforce_private_dns_zone_resolution" {
  type        = bool
  default     = true
  description = "When true, require either private_dns_zone_id or private_dns_zone_rg_name so DNS zone group can be configured."

  validation {
    condition = var.enforce_private_dns_zone_resolution == false || var.private_dns_zone_id != "" || var.private_dns_zone_rg_name != ""
    error_message = "Set private_dns_zone_id or private_dns_zone_rg_name (or disable enforce_private_dns_zone_resolution) to resolve the private DNS zone."
  }
}

#Key Vault settings

variable "sku_name" {
  type    = string
  default = "premium"
}
variable "purge_protection_enabled" {
  type    = bool
  default = true
}

#RBAC data plane for all vaults
variable "rbac_assignments" {
  description = "RBAC principals + roles applied to every regional Key Vault (data-plane)."
  type = list(object({
    principal_id         = string
    role_definition_name = string # e.g., Key Vault Secrets User / Officer / Crypto User / Officer
  }))
  default = []
}

variable "RITM" {
  type = string
  default = ""
}

variable "skip_snow" {
  type = bool
  default = false

}

variable "appcode" {
  type = string
}

variable "appname" {
  type = string
}

variable "costcenter" {
  type = string
}

variable "portfolio" {
  type = string
}

variable "drtier" {
  type = string
}

