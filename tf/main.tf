//terraform {
//  backend "s3" {
//    key = "medium-terraform/prod/terraform.tfstate"
//    # ...
//  }
//}

# https://www.terraform.io/docs/providers/azurerm
provider "azurerm" {
  version = "=1.39.0"
}

# https://www.terraform.io/docs/providers/azuread
provider "azuread" {
  version = "=0.3.1"
}

# Use already created Resource Group.
data "azurerm_resource_group" "env" {
  name = var.resource_group_name
}

//resource "azurerm_route_table" "???" {
//  name                = "${var.prefix}-routetable"
//  location            = "${azurerm_resource_group.example.location}"
//  resource_group_name = "${azurerm_resource_group.example.name}"
//
//  route {
//    name                   = "default"
//    address_prefix         = "10.100.0.0/14"
//    next_hop_type          = "VirtualAppliance"
//    next_hop_in_ip_address = "10.10.1.1"
//  }
//}

# VNet to support multiple AKS clusters.
# For example a /16 vnet allows for 16 /20 subnets.
# The first subnet is reserved for internal load balancers.
resource "azurerm_virtual_network" "env" {
  name                = "${var.env_name}-vnet"
  resource_group_name = var.resource_group_name
  location            = data.azurerm_resource_group.env.location
  address_space       = [var.vnet_cidr]
}
resource "azurerm_subnet" "intlb" {
  name                 = "intlb"
  resource_group_name  = var.resource_group_name
  address_prefix       = cidrsubnet(var.vnet_cidr, var.subnet_newbits, 0)
  virtual_network_name = azurerm_virtual_network.env.name

  # this field is deprecated and will be removed in 2.0 - but is required until then
  //TODO  route_table_id = "${azurerm_route_table.example.id}"
}

//resource "azurerm_subnet_route_table_association" "???" {
//  subnet_id      = "${azurerm_subnet.example.id}"
//  route_table_id = "${azurerm_route_table.example.id}"
//}


# Service principal so AKS can update the vnet.
# Equivalent of: az ad sp create-for-rbac
# https://github.com/terraform-providers/terraform-provider-azuread/issues/40
resource "azuread_application" "vnet-sp" {
  name                       = "${var.env_name}-vnet-sp"
  available_to_other_tenants = false
}
resource "azuread_service_principal" "vnet-sp" {
  application_id = azuread_application.vnet-sp.application_id
}
resource "azuread_service_principal_password" "vnet-sp" {
  service_principal_id = azuread_service_principal.vnet-sp.id
  value                = var.vnet_sp.password
  end_date             = var.vnet_sp.end_date
}
resource "azurerm_role_assignment" "vnet-sp" {
  scope                = azurerm_virtual_network.env.id
  role_definition_name = "Network Contributor"
  //  principal_id       = azuread_service_principal.vnet-sp.application_id //object_id application_id?
  //  principal_id = azuread_application.vnet-sp.id -> Principals of type Application cannot validly be used in role assignments.
  principal_id = azuread_service_principal.vnet-sp.id
}


locals {
  // Tags required by organisation policy.
  tags = {
    // Playground environments require the following tags:
    "FinancialWorkPackageId" = data.azurerm_resource_group.env.tags["FinancialWorkPackageId"]
    "Owner"                  = data.azurerm_resource_group.env.tags["Owner"]
    //TODO check if we really need to propagate these tags:
    "AvailabilityHours" = "1"
    "CIName"            = "cpe-playground-rg"
    "Criticality"       = "Low"
    "EnvironmentType"   = "s"
  }

  // VNet service provider credentials.
  vnet_sp_oauth = {
    client_id     = azuread_service_principal.vnet-sp.application_id
    client_secret = azuread_service_principal_password.vnet-sp.value
  }
}

// TODO Use for_each = var.clusters when it becomes available for modules.
// In the mean time generate module instances.


module "aks1" {
  source = "./modules/aks"

  name = "cpe"
  subnet_num = 1
  k8s_version = "1.14.8"
  scale = 2
  vm_size = "Standard_DS2_v2"

  resource_group = data.azurerm_resource_group.env
  env_name = var.env_name
  vnet = azurerm_virtual_network.env
  subnet_newbits = var.subnet_newbits
  vnet_sp_oauth = local.vnet_sp_oauth
  aad = var.aad
  tags = local.tags
}
/*
module "aks2" {
  source = "./modules/aks"

  name = "test2"
  subnet_num = 2
  k8s_version = "1.14.8"
  scale = 2
  vm_size = "Standard_DS2_v2"

  resource_group = data.azurerm_resource_group.env
  env_name = var.env_name
  vnet = azurerm_virtual_network.env
  subnet_newbits = var.subnet_newbits
  vnet_sp_oauth = local.vnet_sp_oauth
  aad = var.aad
  tags = local.tags
}*/
