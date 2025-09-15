resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.rg_location
  tags = merge(
    var.tags,
    lookup(var.settings, "tags", {})
  )
}
