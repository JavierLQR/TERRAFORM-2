# ================================
# Variables de salida útiles para el usuario
# ================================

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint para acceder al plano de control del EKS"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Nombre del cluster EKS creado"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN del proveedor OIDC (usado con IRSA para roles en pods)"
}
