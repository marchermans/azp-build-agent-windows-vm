provider "azurerm" {
  version = "~>1.39"
}

locals {
  script_parameters = "-AzpAccount ${var.azp_account} -PersonalAccessToken ${var.personal_access_token} -PoolName ${var.pool_name} %{if var.prepare_data_disk}-PrepareDataDisk %{else}-AgentInstallationPath \"${var.agent_installation_path}\" -AgentWorkPath \"${var.agent_work_path}\"%{endif} %{if var.pre_release}-PreRelease%{endif}"
}

resource "azurerm_virtual_machine_extension" "azp_agent_install_agent" {
  count               = length(var.virtual_machines)
  name                = "${element(var.virtual_machines, count.index)}-azp"
  resource_group_name = var.resource_group
  location            = var.location
  tags                = var.tags

  virtual_machine_name = element(var.virtual_machines, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
      "fileUris": [
        "https://raw.githubusercontent.com/lichtblick/azp-build-agent-windows-vm/master/install-azp-agent.ps1"
      ]
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File install-azp-agent.ps1 ${local.script_parameters}"
    }
PROTECTED_SETTINGS
}
