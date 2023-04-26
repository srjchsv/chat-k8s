# Set the provider to Azure
provider "azurerm" {
  use_cli = true
  features {}
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.rg.name
}

locals {
  kube_config = {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = local.kube_config.host
  client_certificate     = local.kube_config.client_certificate
  client_key             = local.kube_config.client_key
  cluster_ca_certificate = local.kube_config.cluster_ca_certificate
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "chat-app-resources"
  location = "eastus"
}

# Create an AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "chat-app-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "chat-app-dns"

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Configure kubectl
resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}"
  }
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}


provider "helm" {
  kubernetes {
    host                   = local.kube_config.host
    client_certificate     = local.kube_config.client_certificate
    client_key             = local.kube_config.client_key
    cluster_ca_certificate = local.kube_config.cluster_ca_certificate
  }
}

# Create namespaces
# Create namespaces
resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "kubernetes_namespace" "myapp" {
  metadata {
    name = "myapp"
  }
}

# Create loadbalancer
resource "helm_release" "ingress-nginx" {
  name       = "my-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
}

# Apply manifests
resource "null_resource" "apply_manifests" {
  provisioner "local-exec" {
    command = "kubectl get service my-nginx-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' > ${path.module}/../external_ip.txt"
  }
  provisioner "local-exec" {
    command = "${path.module}/replace_ip.sh ${path.module}/../manifests/configs/chat-frontend-config.yaml localhost $(cat ${path.module}/../external_ip.txt)"
  }
  provisioner "local-exec" {
    command = "${path.module}/manifests.sh ${path.module}/../manifests ${path.module}/../manifests/ingress/chat-frontend-ingress.yaml"
  }
  provisioner "local-exec" {
    command = "${path.module}/replace_ip.sh ${path.module}/../manifests/configs/chat-frontend-config.yaml $(cat ${path.module}/../external_ip.txt) localhost"
  }
  provisioner "local-exec" {
    command = "rm ${path.module}/../external_ip.txt"
  }
  depends_on = [
    null_resource.kubectl,
    kubernetes_namespace.myapp,
    helm_release.ingress-nginx,
  ]
}
