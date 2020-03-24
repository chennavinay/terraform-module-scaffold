resource "azurerm_resource_group" "core" {
   name         = "CORE"
   location     = "${var.loc}"
   tags         = "${var.tags}"
}

resource "azurerm_virtual_network" "core" {
  name                = "example-network"
  resource_group_name = "${azurerm_resource_group.core.name}"
  location            = "${azurerm_resource_group.core.location}"
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = "${azurerm_resource_group.core.name}"
  virtual_network_name = "${azurerm_virtual_network.core.name}"
  address_prefix       = "10.254.0.0/24"
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = "${azurerm_resource_group.core.name}"
  virtual_network_name = "${azurerm_virtual_network.core.name}"
  address_prefix       = "10.254.2.0/24"
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = "${azurerm_resource_group.core.name}"
  location            = "${azurerm_resource_group.core.location}"
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.core.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.core.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.core.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.core.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.core.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.core.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.core.name}-rdrcfg"
}

/*resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = "${azurerm_resource_group.core.name}"
  location            = "${azurerm_resource_group.core.location}"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${azurerm_subnet.frontend.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.example.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }
}*/

resource "azurerm_resource_group" "nsgs" {
   name         = "NSGs"
   location     = "${var.loc}"
   tags         = "${var.tags}"
}

resource "azurerm_network_security_group" "resource_group_default" {
   name = "ResourceGroupDefault"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"
}

resource "azurerm_network_security_rule" "AllowSSH" {
    name = "AllowSSH"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1010
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 22
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowHTTP" {
    name = "AllowHTTP"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1020
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 80
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}


resource "azurerm_network_security_rule" "AllowHTTPS" {
    name = "AllowHTTPS"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1021
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 443
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowSQLServer" {
    name = "AllowSQLServer"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1030
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 1443
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_group" "nic_ubuntu" {
   name = "NIC_Ubuntu"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = 22
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nic_windows" {
   name = "NIC_Windows"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"

    security_rule {
        name                       = "RDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = 3389
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}