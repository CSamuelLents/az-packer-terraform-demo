provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location

  tags = {
    environment: var.environment
  }
}

resource "azurerm_storage_account" "stor" {
  name                     = "${var.dns_name}stor"
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  tags = {
    environment: var.environment
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "${var.dns_name}avset"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = var.vm_count
  platform_update_domain_count = var.vm_count
  managed                      = true

  tags = {
    environment: var.environment
  }
}

resource "azurerm_public_ip" "lbpip" {
  name                = "${var.rg_prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.lb_ip_dns_name

  tags = {
    environment: var.environment
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = var.location
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment: var.environment
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.rg_prefix}subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_lb" "lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${var.rg_prefix}lb"
  location            = var.location

  tags = {
    environment: var.environment
  }

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackendPool1"

}

resource "azurerm_lb_nat_rule" "tcp" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "RDP-VM-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = 3389
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  count                          = var.vm_count
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.lb_probe.id
  depends_on                     = [azurerm_lb_probe.lb_probe]
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = var.vm_count
}

resource "azurerm_network_interface" "nic" {
  name                = "nic${count.index}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  count               = var.vm_count

  tags = {
    environment: var.environment
  }

  ip_configuration {
    name                                    = "ipconfig${count.index}"
    subnet_id                               = azurerm_subnet.subnet.id
    private_ip_address_allocation           = "Dynamic"
  }
}


resource "azurerm_network_interface_nat_rule_association" "natrule" {
  network_interface_id  = element(azurerm_network_interface.nic.*.id, count.index)
  ip_configuration_name = "ipconfig${count.index}"
  nat_rule_id           = element(azurerm_lb_nat_rule.tcp.*.id, count.index)
  count                 = var.vm_count
}

resource "azurerm_network_security_group" "networksg" {
  name                = "vmSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowInternalTcp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "DenyExternalTcp"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "Internet"
  }

  tags = {
    environment = var.environment
  }
}

data "azurerm_image" "image" {
  name                = "udacity-project-1"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "vm${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  availability_set_id   = azurerm_availability_set.avset.id
  vm_size               = var.vm_size
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = var.vm_count

  tags = {
    environment: var.environment
  }

  storage_image_reference {
    id = data.azurerm_image.image.id
  }

  storage_os_disk {
    name          = "osdisk${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = var.hostname
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
}
