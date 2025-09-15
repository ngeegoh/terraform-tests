# tf_runtime/dataprotection/npd/tests/rg_root.tftest.hcl

# If your root already defines the azurerm provider, you can omit this.
# Otherwise, provide a minimal provider config here for planning.
provider "azurerm" {
  features {}
}

# Make the test deterministic: provide a minimal map with one RG.
# (Alternatively, remove this block and rely on rg.auto.tfvars in the root directory.
#  Terraform tests support typical variable mechanisms; automatic var files in the test
#  directory apply only to tests in that directory, while other mechanisms apply broadly.)
variables {
  resource_groups = {
    rg-itss-dpnp-ntin-npd-aue = {
      name     = "rg-itss-dpnp-ntin-npd-aue"
      location = "australiaeast"
      tags = {
        Owner       = "ItemOwner"      # per-item tag
        Environment = "NPD"
      }
      # reuse defaults to false (your module selection logic uses try(value.reuse, false) == false)
    }
  }

  # "Global" tags provided at root; these are merged in the module call:
  # tags = merge(lookup(each.value, "tags", {}), var.tags)
  # Then inside the module:
  # tags = merge(var.tags, lookup(var.settings, "tags", {}))
  # Net effect: for overlapping keys, the per-item tags (settings.tags) should win.
  tags = {
    Owner      = "GlobalOwner"
    CostCenter = "57786"
  }
}

run "plan_module_instances" {
  command = plan

  # Assert against the single instance we defined above.
  # We use module outputs because module internals are not addressable from the root.
  assert {
    condition     = module.resource_groups["rg-itss-dpnp-ntin-npd-aue"].name == "rg-itss-dpnp-ntin-npd-aue"
    error_message = "Module output 'name' is incorrect for rg-itss-dpnp-ntin-npd-aue"
  }

  assert {
    condition     = module.resource_groups["rg-itss-dpnp-ntin-npd-aue"].location == "australiaeast"
    error_message = "Module output 'location' is incorrect for rg-itss-dpnp-ntin-npd-aue"
  }

  # Overlapping key: per-item tag should win after the two merges
  assert {
    condition     = module.resource_groups["rg-itss-dpnp-ntin-npd-aue"].tags["Owner"] == "ItemOwner"
    error_message = "Tag precedence incorrect: 'Owner' should come from per-item settings"
  }

  # Non-overlapping global key should be preserved
  assert {
    condition     = module.resource_groups["rg-itss-dpnp-ntin-npd-aue"].tags["CostCenter"] == "57786"
    error_message = "Global tag 'CostCenter' should be present on RG"
  }

  # Check the Environment tag from item
  assert {
    condition     = module.resource_groups["rg-itss-dpnp-ntin-npd-aue"].tags["Environment"] == "NPD"
    error_message = "Tag 'Environment' does not match"
  }
}
