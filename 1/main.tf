terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azuread" {}

data "azuread_domains" "default" {}

resource "random_password" "userpass" {
  length  = 16
  special = true
}

resource "azuread_user" "az104_user1" {
  user_principal_name = "az104-user1@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "az104-user1"
  mail_nickname       = "az104user1"
  account_enabled     = true
  password            = random_password.userpass.result
  force_password_change = true
  job_title           = "IT Lab Administrator"
  department          = "IT"
  usage_location      = "US"
}

variable "guest_email" {}
variable "guest_display_name" {}

resource "azuread_user" "guest_user" {
  user_principal_name = "${replace(var.guest_email, "@", "_")}#EXT#@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = var.guest_display_name
  mail                = var.guest_email
  account_enabled     = true
  job_title           = "IT Lab Administrator"
  department          = "IT"
  usage_location      = "US"
}

data "azuread_client_config" "current" {}

resource "azuread_group" "it_lab_admins" {
  display_name     = "IT Lab Administrators"
  description      = "Administrators that manage the IT lab"
  security_enabled = true
  mail_enabled     = false
  mail_nickname    = "it-lab-admins"
  owners           = [data.azuread_client_config.current.object_id]
}

resource "azuread_group_member" "member_internal" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_user.az104_user1.object_id
}

resource "azuread_group_member" "member_guest" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_user.guest_user.object_id
}

output "internal_user_upn" {
  value = azuread_user.az104_user1.user_principal_name
}

output "guest_user_upn" {
  value = azuread_user.guest_user.user_principal_name
}

output "group_name" {
  value = azuread_group.it_lab_admins.display_name
}
