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

# Create azurerm_subnet

resource "azurerm_subnet" "naga_12subnet" {
  name                 = "naga_12subnet"
  resource_group_name  = azurerm_resource_group.naga_12rg.name
  virtual_network_name = azurerm_virtual_network.naga_12vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create azurerm_public_ip

resource "azurerm_public_ip" "naga_12-azurerm_public_ip" {
  name                = "naga_12-public_ip"
  resource_group_name = azurerm_resource_group.naga_12rg.name
  location            = azurerm_resource_group.naga_12rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

# create azurerm_network_security_group

resource "azurerm_network_security_group" "naga_12sg" {
  name                = "naga_12sg"
  location            = azurerm_resource_group.naga_12rg.location
  resource_group_name = azurerm_resource_group.naga_12rg.name
  tags = {
    environment = "dev"
  }
} 

# create azure azurerm_network_security_rule

resource "azurerm_network_security_rule" "naga-12-dev-sg" {
  name                        = "naga-12-dev-sg"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.naga_12rg.name
  network_security_group_name = azurerm_network_security_group.naga_12sg.name
}

# create azurerm_network_interface

resource "azurerm_network_interface" "naga_12az-nic" {
  name                = "naga_12az-nic"
  location            = azurerm_resource_group.naga_12rg.location
  resource_group_name = azurerm_resource_group.naga_12rg.name

  ip_configuration {
    name                          = "naga_12subnet"
    subnet_id                     = azurerm_subnet.naga_12subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.naga_12-azurerm_public_ip.id
  }
} 

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "naga_12-sg-acco" {
  network_interface_id      = azurerm_network_interface.naga_12az-nic.id
  network_security_group_id = azurerm_network_security_group.naga_12sg.id
}

# create azurerm_subnet_network_security_group_association

resource "azurerm_subnet_network_security_group_association" "naga_12nsg_assoc" {
  subnet_id                 = azurerm_subnet.naga_12subnet.id
  network_security_group_id = azurerm_network_security_group.naga_12sg.id
}

# create azurerm_route_table

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

# create azurerm_subnet_route_table_association

resource "azurerm_subnet_route_table_association" "naga_12subnet_route_table_assoc" {
  subnet_id      = azurerm_subnet.naga_12subnet.id
  route_table_id = azurerm_route_table.naga_12rt.id
}

# create azurerm_linux_virtual_machine

resource "azurerm_linux_virtual_machine" "naga_12-vm" {
  name                = "naga12vm"
  resource_group_name = azurerm_resource_group.naga_12rg.name
  location            = azurerm_resource_group.naga_12rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.naga_12az-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = <<-EOT
         private-key or public-key
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

