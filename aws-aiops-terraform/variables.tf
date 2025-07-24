# Define la región AWS donde se desplegará la infraestructura
variable "aws_region" {
  description = "Región de AWS para desplegar recursos"
  type        = string
  default     = "us-east-1"
}

# Define el nombre del bucket S3
variable "bucket_name" {
  description = "Nombre único para el bucket S3"
  type        = string
  default     = "cloudops-ai-advisor-joaquin"
}

# Define el entorno (dev, staging, prod)
variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}
