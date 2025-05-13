# En resumen: este recurso moderniza y refuerza la seguridad de tu bucket, eliminando la necesidad de trabajar con ACLs, que pueden ser confusas y obsoletas. AWS recomienda esta práctica como estándar para entornos seguros.
# Configuración de ACL para el bucket
# Recurso que configura el control de propiedad de objetos en un bucket S3
resource "aws_s3_bucket_ownership_controls" "mi_bucket_ownership_controls" {
  # Especificamos el ID del bucket al que se aplicará este control
  bucket = aws_s3_bucket.mi_bucket_s3.id
  # Definimos la regla de propiedad de los objetos
  rule {
    # Esta opción "BucketOwnerEnforced" hace que:
    # - El propietario del bucket será el propietario de todos los objetos cargados,
    #   incluso si fueron subidos por otro usuario o cuenta.
    # - Las ACLs (listas de control de acceso) quedan completamente desactivadas.
    #   Es decir, no se puede usar "public-read" ni otras ACLs.
    object_ownership = "BucketOwnerEnforced"
  }
}
