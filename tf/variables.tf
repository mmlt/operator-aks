variable "env_domain" {
  description = <<-ETX
    Environment domain is the most significant part of the domain names that gets assigned to services
    running in the cluster.
    Format:
      service.namespace.cluster_name.env_name.env_domain
    service: the k8s service name
    namespace: the k8s namespace of the service
    cluster-name: see variable clusters
    env_name: concatenation of region, cloud provider and env-type,
    env_domain: rest incl TLD, for example; example.com
  ETX
}

variable "env_name" {
  description = "concatenation of region, cloud provider and env-type"
}

variable "resource_group_name" {
  description = "The Resource Group that contains all created resources."
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
      name: name of cluster, also used in domain name; app.namespace.<name>.env.domain
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


