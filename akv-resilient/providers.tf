provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Uses Azure CLI authentication (set by azure/login action)
  # For service principal auth, set ARM_CLIENT_ID and ARM_CLIENT_SECRET env vars
}
