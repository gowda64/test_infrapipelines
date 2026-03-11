#Optional DNS data-source

# If a full private DNS zone ID isnt supplied, look it up by name + RG
data "azurerm_private_dns_zone" "kv" {
    count = var.private_dns_zone_id == "" && var.private_dns_zone_rg_name != ""? 1:0
    name = var.private_dns_zone_name
    resource_group_name = var.private_dns_zone_rg_name  
}

locals {
  effective_private_dns_zone_id = var.private_dns_zone_id != "" ? var.private_dns_zone_id : (length(data.azurerm_private_dns_zone.kv) > 0 ? data.azurerm_private_dns_zone.kv[0].id : null)

    # Build per region KV definitions and standard tags
    vaults ={
        for region, cfg in var.regions:
        region => {
        name = cfg.keyvault_name
            rg = cfg.kv_resource_group
            vnet = cfg.vnet_name
            snet = cfg.subnet_name
            snet_rg = cfg.snet_rg_name
            region = region
        }
    }

    tags ={
        appcode = var.appcode
        appname = var.appname
        costcenter = var.costcenter
        environment = var.environment
        portfolio = var.portfolio
        drtier = var.drtier
    }
}

# Resolve the PE subnet for each region (PE must be in the same region as VNet)
data "azurerm_subnet" "pe" {
    for_each = local.vaults
    name = each.value.snet
    virtual_network_name = each.value.vnet
    resource_group_name = each.value.snet_rg  
}

# Key Vaults

resource "azurerm_key_vault" "kv"{
    for_each = local.vaults
    name = each.value.name
    location = each.value.region
    resource_group_name = each.value.rg

    tenant_id = var.tenant_id
    sku_name = var.sku_name

    # Modern authorization model (preferred)
    rbac_authorization_enabled = true

    # Private only
    public_network_access_enabled = false
    purge_protection_enabled = var.purge_protection_enabled

    network_acls {
      bypass = "AzureServices"
      default_action = "Deny"
      ip_rules = []
    }
    
    tags = local.tags

    lifecycle {
      prevent_destroy = true
    }
}

# Private Endpoints + DNS Zone Group

resource "azurerm_private_endpoint" "pe" {
    for_each = local.vaults
    name = "${each.value.name}-pe"
    location = each.value.region
    resource_group_name = each.value.rg
    subnet_id = data.azurerm_subnet.pe[each.key].id

    private_service_connection {
      name = "${each.value.name}-psc"
      private_connection_resource_id = azurerm_key_vault.kv[each.key].id
      subresource_names = ["vault"]
      is_manual_connection = false
    }

    dynamic "private_dns_zone_group" {
      for_each = local.effective_private_dns_zone_id == null ? [] : [local.effective_private_dns_zone_id]
      content {
        name = var.private_dns_zone_group
        private_dns_zone_ids = [private_dns_zone_group.value]
      }
    }
    
    tags = local.tags
}


# Data-plane RBAC assignments applied to all KVs
resource "azurerm_role_assignment" "kv_data_plane" {
    for_each = {
      for combo in flatten([
        for region, _kv in local.vaults : [
            for r in var.rbac_assignments :
            {
                key = "${region}-${r.principal_id}-${r.role_definition_name}"
                region = region 
                principal_id = r.principal_id
                role_definition_name = r.role_definition_name
            }
        ]
      ]) : combo.key => combo 
    }
    scope = azurerm_key_vault.kv[each.value.region].id
    role_definition_name = each.value.role_definition_name
    principal_id = each.value.principal_id
}