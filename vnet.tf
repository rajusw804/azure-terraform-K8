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

resource "azurerm_resource_group" "naga_12rg" {
  name     = "naga_12rg"
  location = "West Europe"
}

# Create a virtual network within the resource group

resource "azurerm_virtual_network" "naga_12vnet" {
  name                = "naga_12vnet"
  resource_group_name = azurerm_resource_group.naga_12rg.name
  location            = azurerm_resource_group.naga_12rg.location
  address_space       = ["10.0.0.0/16"]
}

# azurerm_subnet

resource "azurerm_subnet" "naga_12subnet" {
  name                 = "naga_12subnet"
  resource_group_name  = azurerm_resource_group.naga_12rg.name
  virtual_network_name = azurerm_virtual_network.naga_12vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# azurerm_network_security_group

resource "azurerm_network_security_group" "naga_12sg" {
  name                = "naga_12sg"
  location            = azurerm_resource_group.naga_12rg.location
  resource_group_name = azurerm_resource_group.naga_12rg.name
tags = {
    environment = "dev"
  }
} 

# azure azurerm_network_security_rule
resource "azurerm_network_security_rule" "naga-12-dev-sg" {
  name                        = "naga-12-dev-sg"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.naga_12rg.name
  network_security_group_name = azurerm_network_security_group.naga_12sg.name
}

#azurerm_subnet_network_security_group_association

resource "azurerm_subnet_network_security_group_association" "naga_12nsg_assoc" {
  subnet_id                 = azurerm_subnet.naga_12subnet.id
  network_security_group_id = azurerm_network_security_group.naga_12sg.id
}

# azurerm_route_table

resource "azurerm_route_table" "naga_12rt" {
  name                          = "naga_12_route_table"
  location                      = azurerm_resource_group.naga_12rg.location
  resource_group_name           = azurerm_resource_group.naga_12rg.name
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

resource "azurerm_subnet_route_table_association" "naga_12subnet_route_table_assoc" {
  subnet_id      = azurerm_subnet.naga_12subnet.id
  route_table_id = azurerm_route_table.naga_12rt.id
}

