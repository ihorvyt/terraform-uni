terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "East US"
  tags = {
    "Cost Center" = "000"
  }
}

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag and its value on resources"
}

resource "azurerm_resource_group_policy_assignment" "require_cost_center_tag" {
  name                 = "RequireCostCenterTag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id

  parameters = jsonencode({
    tagName = {
      value = "Cost Center"
    }
    tagValue = {
      value = "000"
    }
  })

  description = "Require Cost Center tag and its value on all resources in the resource group"
}


data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

resource "azurerm_user_assigned_identity" "policy_identity" {
  name                = "policy-managed-identity"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
}

resource "azurerm_resource_group_policy_assignment" "inherit_cost_center_tag" {
  name                 = "InheritCostCenterTag"
  resource_group_id    = azurerm_resource_group.rg2.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  location             = azurerm_resource_group.rg2.location

  parameters = jsonencode({
    tagName = {
      value = "Cost Center"
    }
  })

  description = "Inherit the Cost Center tag and its value 000 from the resource group if missing"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.policy_identity.id]
  }
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
  notes      = "Lock to prevent accidental deletion of resource group az104-rg2"
}

