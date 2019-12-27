variable "resource_group_name" {
  description = "The Resource Group that contains all created resources."
}

variable "env_name" {
  //  TODO for globally unique resources we need something more unique (domain name)
  description = <<-ETX
    Environment name is used a prefix for resources and as part of the domain name of services running in the clusters.
      format: app.namespace.cluster-name.<env-name>.subdomain
      example: app.namespace.cluster-name.k8ss.example.com
    Typically "k8s{data.azurerm_resource_group.env.tags[EnvironmentType]}"
  ETX
}

variable "vnet_cidr" {
  description = "Address range of VNet in which AKS clusters get a subnet."
}

variable "subnet_newbits" {
  description = <<-ETX
    Subnet newbits is the number of bits to add to the VNet address mask to produce the subnet mask.
    For example given a /16 VNet and subnet_newbits=4 would result in /20 subnets.
  ETX
  type        = number
}

variable "vnet_sp" {
  description = "Secret of Service Principal that AKS uses to access VNet"
  type = object({
    password = string
    end_date = string
  })
}

variable "aad" {
  description = "AzureAD app's used by clusters for RBAC of users."
  type = object({
    tenant_id         = string
    server_app_id     = string
    server_app_secret = string
    client_app_id     = string
  })
}

variable "clusters" {
  description = <<-ETX
    List of AKS clusters specs.
      name: name of cluster, also used in domain name; app.namespace.<name>.env.subdomain
      subnet_num: subnet of vnet that is used by this cluster. Min: 1 Max: (vnet_cidr/subnet_cidr)-1
      version: kubernetes version
      scale: number of worker nodes
      vm_size: type of worker nodes
    TODO This will have to wait until 'for_each for modules' is supported.
    https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
    https://github.com/hashicorp/terraform/issues/17519
  ETX
  type = list(object({
    name       = string
    subnet_num = number
    version    = string
    scale      = number
    vm_size    = string
  }))
}


