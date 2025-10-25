# Step 1
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg4"
  location = "East US"
}

# Step 1
resource "azurerm_virtual_network" "core_services_vnet" {
  name                = "CoreServicesVnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Step 1
resource "azurerm_subnet" "shared_services_subnet" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_services_vnet.name
  address_prefixes     = ["10.20.10.0/24"]
}

# Step 1
resource "azurerm_subnet" "database_subnet" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_services_vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}

# Step 3
resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_group" "myNSGSecure" {
  name                = "myNSGSecure"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}


resource "azurerm_subnet_network_security_group_association" "sharedservices_nsg" {
  subnet_id                 = azurerm_subnet.shared_services_subnet.id
  network_security_group_id = azurerm_network_security_group.myNSGSecure.id
}

# Step 3
resource "azurerm_network_security_rule" "allow_asg" {
  name                        = "AllowASG"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.myNSGSecure.name
  resource_group_name         = azurerm_network_security_group.myNSGSecure.resource_group_name
}

# Step 3
resource "azurerm_network_security_rule" "deny_internet_outbound" {
  name                        = "DenyInternetOutbound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  destination_port_range      = "*"
  network_security_group_name = azurerm_network_security_group.myNSGSecure.name
  resource_group_name         = azurerm_network_security_group.myNSGSecure.resource_group_name
}

# Step 4
resource "azurerm_dns_zone" "public_zone" {
  name                = "myuniquedomain12345.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_a_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = ["10.1.1.4"]
}

resource "azurerm_private_dns_zone" "private_zone" {
  name                = "private.contoso.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "manufacturing_vnet" {
  name                = "ManufacturingVnet"
  address_space       = ["10.30.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "manufacturing_link" {
  name                  = "manufacturing-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_zone.name
  virtual_network_id     = azurerm_virtual_network.manufacturing_vnet.id
  registration_enabled   = false
}

resource "azurerm_private_dns_a_record" "sensorvm" {
  name                = "sensorvm"
  zone_name           = azurerm_private_dns_zone.private_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = ["10.1.1.4"]
}
