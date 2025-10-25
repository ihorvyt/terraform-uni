resource "azurerm_resource_group_template_deployment" "disk_deployment" {
  name                = "diskDeployment3"
  resource_group_name = azurerm_resource_group.lab_rg.name
  deployment_mode     = "Incremental"

  template_content    = file("${path.module}/template.json")

  parameters_content  = jsonencode({
    disks_az104_disk1_name = {
      value = "az104-disk3"
    }
  })

  depends_on = [azurerm_resource_group.lab_rg]
}
