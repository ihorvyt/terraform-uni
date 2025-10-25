# Step 1
resource "azurerm_resource_group" "lab_rg" {
  name     = "az104-rg3"
  location = "East US"
}

# Step 1
resource "azurerm_managed_disk" "lab_disk1" {
  name                 = "az104-disk1"
  location             = azurerm_resource_group.lab_rg.location
  resource_group_name  = azurerm_resource_group.lab_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

# Step 2
resource "azurerm_managed_disk" "lab_disk2" {
  name                 = "az104-disk2"
  location             = azurerm_resource_group.lab_rg.location
  resource_group_name  = azurerm_resource_group.lab_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}
