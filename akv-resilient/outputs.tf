output "vault_uris" {
    description = "Region => Vault URI"
    value = { for r, kv in azurerm_key_vault.kv : r => kv.vault_uri}
  
}

output "key_vault_ids" {
    description = "Region => Key Vault resource IDs"
    value = { for r,kv in azurerm_key_vault.kv : r => kv.id}
    
}

output "private_endpoint_ids" {
  description = "Region => Private Endpoint resource IDs"
  value = { for r, pe in azurerm_private_endpoint.pe : r => pe.id}
}