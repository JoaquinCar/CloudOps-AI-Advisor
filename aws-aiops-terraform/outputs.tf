#Este archivo indica qué información quieres que Terraform te muestre después de crear o actualizar recursos.

# URL del bucket (útil si lo haces público o usas hosting)
output "bucket_domain_name" {
  description = "El nombre de dominio del bucket S3"
  value       = aws_s3_bucket.log_bucket.bucket_domain_name
}

# Región donde se creó
output "bucket_region" {
  description = "La región donde fue creado el bucket"
  value       = var.aws_region
}

# Nombre del entorno (dev, staging, prod)
output "deployment_environment" {
  description = "Ambiente de despliegue usado"
  value       = var.environment
}

# Nombre del bucket desde variable (útil si usas random o prefijos)
output "custom_bucket_name_from_variable" {
  description = "El nombre del bucket desde variable"
  value       = var.bucket_name
}
output "cloudtrail_name" {
  value = aws_cloudtrail.cloudtrail.name
}
