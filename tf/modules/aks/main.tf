# AKS cluster with Advanced networking and AAD integration.
# Each AKS cluster get it's own subnet in the vnet.
# https://www.terraform.io/docs/providers/azurerm/r/kubernetes_cluster.html

resource "azurerm_subnet" "this" {
  name                 = var.name
  resource_group_name  = var.resource_group.name
  address_prefix       = cidrsubnet(var.vnet.address_space[0], var.subnet_newbits, var.subnet_num)
  virtual_network_name = var.vnet.name

  # this field is deprecated and will be removed in 2.0 - but is required until then
  //TODO  route_table_id = "${azurerm_route_table.example.id}"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.env_name}-${var.name}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  dns_prefix          = "${var.env_name}-${var.name}"

  //TODO enable  enable_pod_security_policy = true
  kubernetes_version = var.k8s_version

  /*TODO remove  linux_profile {
    admin_username = "user1"
    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }*/

  // TODO remove; agent_pool_profile is deprecated and will be replaced by default_node_pool
  /*  agent_pool_profile {
    name            = "agentpool1"
    count           = "2"
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.this.id
  }*/

  default_node_pool {
    name    = "default"
    vm_size = var.vm_size
    #max_pods  =
    type = "VirtualMachineScaleSets"
    // Autoscaling
    enable_auto_scaling = false
    node_count          = var.scale
    // TODO Enable node autoscaler
    #enable_auto_scaling = true
    #max_count = 10
    #min_count = 1
    #node_count = 2

    #availability_zones = [1,2]
    #os_disk_size_gb
    #node_taints

    vnet_subnet_id = azurerm_subnet.this.id
  }


  service_principal {
    client_id     = var.vnet_sp_oauth.client_id
    client_secret = var.vnet_sp_oauth.client_secret
  }

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "azure"
    //TODO enable    network_policy     = "calico"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      tenant_id         = var.aad.tenant_id
      server_app_id     = var.aad.server_app_id
      server_app_secret = var.aad.server_app_secret
      client_app_id     = var.aad.client_app_id
    }
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  tags = var.tags
}

