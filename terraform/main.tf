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
      API_URL   = "${aws_apigatewayv2_api.mock_api.api_endpoint}/api/incidents"
    }
  }

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}


resource "aws_lambda_function" "mock_api" {
  function_name = "serverless-ops-mock-api"

  filename         = "${path.module}/../lambda/mock_api/mock_api.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/mock_api/mock_api.zip")

  role    = aws_iam_role.lambda_role.arn
  handler = "app.lambda_handler"
  runtime = "python3.10"

  timeout     = 10
  memory_size = 128

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}

resource "aws_apigatewayv2_api" "mock_api" {
  name          = "serverless-ops-mock-api"
  protocol_type = "HTTP"

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}


resource "aws_apigatewayv2_integration" "mock_api_lambda" {
  api_id = aws_apigatewayv2_api.mock_api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.mock_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "incidents" {
  api_id = aws_apigatewayv2_api.mock_api.id

  route_key = "GET /api/incidents"

  target = "integrations/${aws_apigatewayv2_integration.mock_api_lambda.id}"
}


resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.mock_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Project     = "serverless-ops-reporting"
    Environment = "dev"
  }
}
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mock_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.mock_api.execution_arn}/*/GET/api/incidents"
}
