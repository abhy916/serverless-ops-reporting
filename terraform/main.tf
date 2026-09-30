terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "reports" {
  bucket_prefix = "serverless-ops-reporting-"

  tags = {
    Name        = "Serverless Operations Reports"
    Environment = "dev"
    Project     = "serverless-ops-reporting"
  }
}
resource "aws_iam_role" "lambda_role" {
  name = "serverless-ops-reporting-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "lambda.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "serverless-ops-reporting-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.reports.arn}/reports/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "report_generator" {
  function_name = "serverless-ops-report-generator"

  filename         = "${path.module}/../lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda_function.zip")

  role    = aws_iam_role.lambda_role.arn
  handler = "report_generator.lambda_handler"
  runtime = "python3.10"

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.reports.bucket
    }
  }

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}
