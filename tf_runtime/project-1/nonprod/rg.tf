module "resource_groups" {
  source = "../../../modules/rg"
  for_each = {
    for key, value in try(var.resource_groups, {}) : key => value
    if try(value.reuse, false) == false
  }

  resource_group_name = each.value.name
  rg_location            = each.value.location
  tags                = /* each.value.tags */merge(lookup(each.value, "tags", {}), var.tags)
  settings            = each.value
}
