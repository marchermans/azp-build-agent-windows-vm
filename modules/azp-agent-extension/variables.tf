variable "virtual_machines" {
  type        = list(string)
  description = "Virtual machine names."
}

variable "resource_group" {
  type        = string
  description = "Name of resource group."
}

variable "location" {
  type        = string
  description = "Location for azure resource."
}

variable "tags" {
  type        = map(string)
  description = "Virtual machine extension's resource tags."
  default     = {}
}

variable "azp_account" {
  type        = string
  description = "Azure Pipelines account name (e.g. from http://dev.azure.com/<account name>)."
}

variable "personal_access_token" {
  type        = string
  description = "Personal Access Token to join Azure Pipelines agent pool."
}

variable "pool_name" {
  type        = string
  description = "Azure Pipelines agent pool name (default is 'Default')."
  default     = "Default"
}

variable "prepare_data_disk" {
  type        = bool
  description = "Prepares and uses a data disk for agent installation. Agent will be installed to drive 'P:'."
  default     = false
}

variable "agent_installation_path" {
  type        = string
  description = "Install path for agent on virtual machine."
  default     = "C:/Azure-Pipelines-Agent"
}

variable "agent_work_path" {
  type        = string
  description = "Working directory for agent builds on virtual machine."
  default     = "C:/Azure-Pipelines-Agent/_work"
}