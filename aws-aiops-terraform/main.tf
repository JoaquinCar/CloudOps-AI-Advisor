# 1. Proveedor AWS
provider "aws" {
  region = var.aws_region
}

# 2. Recurso: Bucket S3
# "aws_s3_bucket" → tipo de recurso que quieres crear, en este caso un bucket de Amazon S3.
# "log_bucket" es el nombre local (o identificador) que le das a este recurso dentro de Terraform.
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_name # Nombre del bucket, definido en las variables,nombre real que tendrá el bucket en AWS (debe ser único globalmente).

  tags = {
    Name        = "LogStorage"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
resource "aws_s3_bucket_policy" "log_bucket_policy" { # Política del bucket S3
  bucket = aws_s3_bucket.log_bucket.id                # Aquí le dices a qué bucket se aplica la política, usando su ID (que es el nombre real del bucket).

  policy = jsonencode({
    Version = "2012-10-17" # Versión de la política de AWS, que define cómo se interpretan las reglas.
    Statement = [
      {
        Sid    = "AWSCloudTrailWrite" # Identificador de la declaración, útil para identificarla.
        Effect = "Allow"              # Efecto de la política, en este caso "Allow" significa que se permite la acción.
        Principal = {
          Service = "cloudtrail.amazonaws.com" # Principal es el servicio que está autorizado a realizar acciones en el bucket, en este caso CloudTrail.
        }
        Action   = "s3:GetBucketAcl"                             # Acción permitida, en este caso permite a CloudTrail obtener el ACL del bucket.
        Resource = "arn:aws:s3:::${aws_s3_bucket.log_bucket.id}" # Recurso al que se aplica la acción, en este caso el bucket S3.
      },
      {
        Sid    = "AWSCloudTrailWrite2"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject" # Acción permitida, en este caso permite a CloudTrail escribir objetos en el bucket.
        Resource = "arn:aws:s3:::${aws_s3_bucket.log_bucket.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control" # Condición que especifica que el ACL del objeto debe ser "bucket-owner-full-control", lo que significa que el propietario del bucket tendrá control total sobre los objetos escritos por CloudTrail.
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {} # Obtiene información sobre la identidad del usuario o rol que está ejecutando Terraform, como el ID de cuenta de AWS.

#Declara el recurso aws_cloudtrail y le da el nombre lógico cloudtrail para que Terraform lo gestione.
resource "aws_cloudtrail" "cloudtrail" {
  name                          = "aiops-cloudtrail"          #Nombre del trail en AWS. Visible en la consola.
  s3_bucket_name                = aws_s3_bucket.log_bucket.id #Le decimos a CloudTrail que envíe los archivos de log al bucket S3 que ya creaste (log_bucket). Lo hace usando su id, que es el nombre real del bucket.
  include_global_service_events = true                        #Captura eventos de servicios globales como IAM, STS, etc. Muy útil para seguridad.
  is_multi_region_trail         = true                        #Permite que el trail capture eventos de todas las regiones de AWS, no solo de la región donde se creó.
  enable_log_file_validation    = true                        #Habilita la validación de los archivos de log para asegurarte de que no han sido alterados.

  event_selector {
    read_write_type           = "All" # Registra tanto operaciones de lectura (GetObject, DescribeInstances) como de escritura (PutObject, StartInstances).
    include_management_events = true  # Incluye eventos de gestión, como cambios en la configuración de recursos.
  }

  tags = {
    Name        = "CloudTrail"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "aiops_lambda_exec_role" # Nombre del rol de ejecución de Lambda, que se usará para otorgar permisos a la función Lambda.

  assume_role_policy = jsonencode({ # Política de confianza que permite a Lambda asumir este rol.
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com" # Principal es el servicio que puede asumir este rol, en este caso Lambda.
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name                                 # Aquí le dices a qué rol se le adjunta la política.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # Esta política otorga permisos básicos de ejecución a la función Lambda, como escribir logs en CloudWatch.
}

resource "aws_iam_user" "lambda_user" { # Crea un usuario IAM para la función Lambda
  name = "lambda-exec-user"             # Nombre del usuario IAM, que se usará para otorgar permisos a la función Lambda.
}

resource "aws_iam_access_key" "lambda_user_key" {
  user = aws_iam_user.lambda_user.name # Aquí le dices a qué usuario se le crea la clave de acceso.
}

resource "aws_iam_user_policy_attachment" "lambda_basic_execution" {
  user       = aws_iam_user.lambda_user.name # Aquí le dices a qué usuario se le adjunta la política.
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "example_lambda" {
  function_name = "aiops_example_lambda"                 # Nombre de la función Lambda, que se usará para ejecutar el código.
  description   = "Función Lambda de ejemplo para AIOps" # Descripción de la función Lambda, que se mostrará en la consola de AWS.
  handler       = "index.handler"                        # index.py -> def handler(event, context)           # Nombre del archivo y la función que se ejecutará cuando se invoque la función Lambda. Aquí, "index" es el nombre del archivo (sin extensión) y "handler" es la función dentro de ese archivo.
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec_role.arn

  filename         = "lambda_function_payload.zip"                   # Archivo ZIP que contiene el código de la función Lambda. Debes crear este archivo antes de aplicar la configuración de Terraform.
  source_code_hash = filebase64sha256("lambda_function_payload.zip") # Hash del código fuente para verificar que no ha cambiado desde la última implementación.

  environment {
    variables = {
      ENV = var.environment
    }
  }
}

