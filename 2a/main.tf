terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
  }
  required_version = ">=1.2.0"
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

variable "tenant_id" {
  type = string
}

variable "subscription_ids" {
  type = list(string)
  default = []
}

variable "helpdesk_group_name" {
  type    = string
  default = "helpdesk"
}

resource "azurerm_management_group" "az104_mg1" {
  name         = "az104-mg1"
  display_name = "az104-mg1"
  tenant_id    = var.tenant_id
}

resource "azurerm_management_group_subscription" "mg_subscriptions" {
  for_each = toset(var.subscription_ids)
  management_group_id = azurerm_management_group.az104_mg1.id
  subscription_id     = each.value
}

data "azuread_group" "helpdesk" {
  display_name = var.helpdesk_group_name
}

data "azurerm_role_definition" "vm_contributor" {
  name  = "Virtual Machine Contributor"
  scope = azurerm_management_group.az104_mg1.id
}

resource "azurerm_role_assignment" "vm_contributor_helpdesk" {
  scope              = azurerm_management_group.az104_mg1.id
  role_definition_id = data.azurerm_role_definition.vm_contributor.role_definition_id
  principal_id       = data.azuread_group.helpdesk.object_id
  depends_on         = [azurerm_management_group.az104_mg1]
}

resource "random_uuid" "custom_support_role_id" {}

resource "azurerm_role_definition" "custom_support_request" {
  name               = random_uuid.custom_support_role_id.result
  role_definition_id = random_uuid.custom_support_role_id.result
  scope              = azurerm_management_group.az104_mg1.id
  display_name       = "Custom Support Request"
  description        = "A custom contributor role for support requests."
  permissions {
    actions = [
      "Microsoft.Support/*/read",
      "Microsoft.Support/*/write",
      "Microsoft.Support/supportTickets/*",
      "Microsoft.Compute/virtualMachines/*/read",
      "Microsoft.Compute/virtualMachines/*/write",
      "Microsoft.Compute/virtualMachineScaleSets/*/read",
      "Microsoft.Compute/virtualMachineScaleSets/*/write"
    ]
    not_actions = [
      "Microsoft.Resources/subscriptions/resourceProviders/register/action"
    ]
    data_actions = []
    not_data_actions = []
  }
  assignable_scopes = [azurerm_management_group.az104_mg1.id]
}

resource "azurerm_role_assignment" "custom_support_helpdesk" {
  scope              = azurerm_management_group.az104_mg1.id
  role_definition_id = azurerm_role_definition.custom_support_request.role_definition_resource_id
  principal_id       = data.azuread_group.helpdesk.object_id
  depends_on         = [azurerm_role_definition.custom_support_request]
}
