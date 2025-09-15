# modules/rg/tests/rg_module.tftest.hcl

provider "azurerm" {
  features {}
}

# Inputs for THIS MODULE under test
variables {
  resource_group_name = "tst-rg-module"
  rg_location         = "australiaeast"

  # "Global" tags passed as var.tags
  tags = {
    Owner        = "GlobalOwner"
    Environment  = "Test"
    CostCenter   = "57786"
  }

  # settings.tags should override duplicates from var.tags inside the module
  settings = {
    tags = {
      Owner = "ModuleOverride"
    }
  }
}

# Plan-only is enough for static attributes (name/location/tags).
# Use command = apply if you want to assert on values known only after creation (e.g., IDs).
run "plan_resource_group" {
  command = plan

  assert {
    condition     = azurerm_resource_group.rg.name == var.resource_group_name
    error_message = "Resource group name does not match"
  }

  assert {
    condition     = azurerm_resource_group.rg.location == var.rg_location
    error_message = "Resource group location does not match"
  }

  # Non-overlapping key should remain from var.tags
  assert {
    condition     = azurerm_resource_group.rg.tags["Environment"] == "Test"
    error_message = "Tag 'Environment' does not match"
  }

  # Overlapping key should be overridden by settings.tags due to merge order in the module
  assert {
    condition     = azurerm_resource_group.rg.tags["Owner"] == "ModuleOverride"
    error_message = "Tag 'Owner' precedence is incorrect"
  }

  # Another non-overlapping key should pass through
  assert {
    condition     = azurerm_resource_group.rg.tags["CostCenter"] == "57786"
    error_message = "Tag 'CostCenter' does not match"
  }

  # Validate outputs align with resource attributes
  assert {
    condition     = output.name == azurerm_resource_group.rg.name
    error_message = "Output 'name' does not match resource"
  }
  assert {
    condition     = output.location == azurerm_resource_group.rg.location
    error_message = "Output 'location' does not match resource"
  }
}
