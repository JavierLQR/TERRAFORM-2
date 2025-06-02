
#this does work(esto si funciona)

provider "aws" {
  region = "us-east-1"
}

# VPC Module for EKS
module "vpc" {
  # Fuente del módulo desde el registro oficial de Terraform
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Usa una versión compatible con la 5.x

  name = "nestjs-eks-vpc" # Nombre de la VPC que se creará en AWS
  cidr = "10.0.0.0/16"    # Rango de IPs privadas de la red (10.0.0.0 a 10.0.255.255)

  azs             = ["us-east-1a", "us-east-1b"]       # Zonas de disponibilidad donde se crearán subredes
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]     # Subredes privadas, usadas por los nodos del EKS
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # Subredes públicas, usadas por balanceadores, etc.

  enable_nat_gateway     = true  # Activa NAT Gateway para que las privadas accedan a Internet
  single_nat_gateway     = true  # Usará un solo NAT Gateway para toda la VPC (más barato)
  one_nat_gateway_per_az = false # No crea un NAT Gateway por AZ (ahorra costos)

  tags = {
    "kubernetes.io/cluster/nestjs-eks-cluster" = "shared" # Necesario para que EKS reconozca las subredes
    Environment                                = "dev"    # Etiqueta para identificar el entorno (desarrollo)
  }
}


# EKS Module
# ================================
# Módulo de EKS (Amazon Kubernetes Service)
# ================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws" # Fuente del módulo EKS oficial
  version = "~> 20.0"                       # Versión compatible de la 20.x

  cluster_name    = "nestjs-eks-cluster" # Nombre que tendrá tu cluster EKS
  cluster_version = "1.32"               # Versión de Kubernetes a usar en el cluster

  vpc_id                   = module.vpc.vpc_id          # ID de la VPC creada previamente
  subnet_ids               = module.vpc.private_subnets # Subredes donde correrán los nodos
  control_plane_subnet_ids = module.vpc.private_subnets # Subredes para el plano de control (privadas)

  enable_irsa = true # Activa IRSA: permite usar IAM roles en pods

  cluster_endpoint_public_access           = true # Permite acceso público al endpoint del cluster (cuidado en producción)
  enable_cluster_creator_admin_permissions = true # Da permisos de admin al creador del cluster

  # ================================
  # Nodo administrado por EKS
  # ================================
  eks_managed_node_groups = {
    ng-1 = {
      name           = "ng-1"        # Nombre del grupo de nodos
      instance_types = ["t3.medium"] # Tipo de instancia EC2 para los nodos
      desired_size   = 2             # Cuántas instancias deseas iniciar inicialmente
      min_size       = 1             # Escalado mínimo
      max_size       = 3             # Escalado máximo
      capacity_type  = "ON_DEMAND"   # Tipo de capacidad: bajo demanda
      disk_size      = 20            # Tamaño del disco en GB
    }
  }

  tags = {
    Environment = "dev" # Etiqueta que identifica el entorno (desarrollo)
  }
}


# ================================
# Actualiza tu archivo kubeconfig local para conectarte al EKS
# ================================

resource "null_resource" "update_kubeconfig" {
  depends_on = [module.eks] # Espera a que el módulo EKS esté completamente creado antes de ejecutar

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name nestjs-eks-cluster" # Ejecuta en tu máquina local el comando que configura tu kubectl apuntando al cluster EKS creado
    # Este comando agrega (o actualiza) una entrada en tu archivo ~/.kube/config para que kubectl sepa cómo conectarse al cluster
  }
}
