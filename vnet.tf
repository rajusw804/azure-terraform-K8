terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider

provider "azurerm" {
  features {}
}

# Create a resource group

resource "azurerm_resource_group" "naga_12rgprat" {
  name     = "naga_12rgprat"
  location = "West Europe"
}

# Create a virtual network within the resource group

resource "azurerm_virtual_network" "naga_12vnetprat" {
  name                = "naga_12vnetprat"
  resource_group_name = azurerm_resource_group.naga_12rgprat.name
  location            = azurerm_resource_group.naga_12rgprat.location
  address_space       = ["10.0.0.0/16"]
}

# Create azurerm_subnet

resource "azurerm_subnet" "naga_12subnetprat" {
  name                 = "naga_12subnetprat"
  resource_group_name  = azurerm_resource_group.naga_12rgprat.name
  virtual_network_name = azurerm_virtual_network.naga_12vnetprat.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create azurerm_public_ip

resource "azurerm_public_ip" "naga_12-azurerm_public_ipprat" {
  name                = "naga_12-public_ipprat"
  resource_group_name = azurerm_resource_group.naga_12rgprat.name
  location            = azurerm_resource_group.naga_12rgprat.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

# create azurerm_network_security_group

resource "azurerm_network_security_group" "naga_12sgprat" {
  name                = "naga_12sgprat"
  location            = azurerm_resource_group.naga_12rgprat.location
  resource_group_name = azurerm_resource_group.naga_12rgprat.name
  tags = {
    environment = "dev"
  }
} 

# create azure azurerm_network_security_rule

resource "azurerm_network_security_rule" "naga-12-dev-sgprat" {
  name                        = "naga-12-dev-sgprat"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.naga_12rgprat.name
  network_security_group_name = azurerm_network_security_group.naga_12sgprat.name
}

# create azurerm_network_interface

resource "azurerm_network_interface" "naga_12az-nicprat" {
  name                = "naga_12az-nicprat"
  location            = azurerm_resource_group.naga_12rgprat.location
  resource_group_name = azurerm_resource_group.naga_12rgprat.name

  ip_configuration {
    name                          = "naga_12subnetprat"
    subnet_id                     = azurerm_subnet.naga_12subnetprat.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.naga_12-azurerm_public_ipprat.id
  }
} 

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "naga_12-sg-accoprat" {
  network_interface_id      = azurerm_network_interface.naga_12az-nicprat.id
  network_security_group_id = azurerm_network_security_group.naga_12sgprat.id
}

# create azurerm_subnet_network_security_group_association

resource "azurerm_subnet_network_security_group_association" "naga_12nsg_assocprat" {
  subnet_id                 = azurerm_subnet.naga_12subnetprat.id
  network_security_group_id = azurerm_network_security_group.naga_12sgprat.id
}

# create azurerm_route_table

resource "azurerm_route_table" "naga_12rtprat" {
  name                          = "naga_12_route_tableprat"
  location                      = azurerm_resource_group.naga_12rgprat.location
  resource_group_name           = azurerm_resource_group.naga_12rgprat.name
  # disable_bgp_route_propagation = false

  route {
    name           = "naga_12_route_table"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VnetLocal"
  }

  tags = {
    environment = "dev"
  }
}

# create azurerm_subnet_route_table_association

resource "azurerm_subnet_route_table_association" "naga_12subnet_route_table_assocprat" {
  subnet_id      = azurerm_subnet.naga_12subnetprat.id
  route_table_id = azurerm_route_table.naga_12rtprat.id
}

# create azurerm_linux_virtual_machine

resource "azurerm_linux_virtual_machine" "naga_12-vm" {
  name                = "naga12vm"
  resource_group_name = azurerm_resource_group.naga_12rgprat.name
  location            = azurerm_resource_group.naga_12rgprat.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.naga_12az-nicprat.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = <<-EOT
         ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQColOtAOZCA7F+bqA2/fVNzMaDaCT0vXMEfv04GbrZJCOYMqcb+HoBP6vQdHuol+8910ic5agp/z7hHtlLXtCeQtBFVIDHGuw4StFDT3vvYsGs5KtjzPsKCiLFNfdeOTMoim5dD4vJrExAa7dJ510TN4vkYB8T92nyut6z4cXLPeG+IfMFssOiuB9IQJfA39hpO4tvY6rBi4UbCsTbtG9/6BItYgvVfMERzJKhW/cKMN9dnFzCosx9uQSOjy9nGhlvMeSwvLtkPRKZFSs+To+Uii6OEHe3b69W/q1/3+OJJg5PVfgFaZqTz1itXP2rDmIQX7f3qfmy2iQHokynFo/0wcNZoTYtQF2Gt4ykcmqlNikr4k3EKayIbc/4IMma6sOkJINp6iAVGfajbZLPX8isjPsa/WPWa6IPmGgyLJUrkwV0qkJ53ZDBPemTW+21RrfZA6n6tLkFn4zl4s+bWpSsRrNXcfhhfcmfWWm9zSmbgmKMcLNXuE0KGdXsyVycNX2U= padmalingareddy\padmalingareddy@PadmaLingareddy 
      EOT
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_kubernetes_cluster" "naga_12cluster" {
  name                = "naga_12clusterprat-aks1"
  location            = azurerm_resource_group.naga_12rgprat.location
  resource_group_name = azurerm_resource_group.naga_12rgprat.name
  dns_prefix          = "nagaclusteraks1prat"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "dev"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.naga_12cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.naga_12cluster.kube_config_raw
  sensitive = true
}