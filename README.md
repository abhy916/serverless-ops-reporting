# Serverless Ops Reporting

A serverless incident reporting pipeline built using AWS Lambda, API Gateway, Amazon S3, IAM, and Terraform.

The project demonstrates how to retrieve operational incident data from an HTTP API, generate a summary report, and store the results in Amazon S3.

## Architecture

```text
                  Manual Invocation
                         |
                         v
                 Reporting Lambda
                         |
                         | HTTPS GET /api/incidents
                         v
                    API Gateway
                         |
                         v
                   Mock API Lambda
                         |
                         | Incident JSON
                         v
                 Reporting Lambda
                         |
                         | PutObject
                         v
                    Amazon S3
               reports/latest-report.json
```

## AWS Services Used

| Service | Purpose |
|---|---|
| AWS Lambda | Runs the mock incident API and report generator |
| API Gateway | Exposes the incident API over HTTPS |
| Amazon S3 | Stores generated JSON reports |
| AWS IAM | Controls Lambda execution and S3 access |
| Amazon CloudWatch | Collects Lambda execution logs |
| Terraform | Provisions and manages AWS infrastructure |

## Project Structure

```text
serverless-ops-reporting/
├── lambda/
│   ├── report_generator.py
│   └── mock_api/
│       └── app.py
├── terraform/
│   └── main.tf
├── mock-api/
├── sample-data/
├── docs/
├── requirements.txt
└── README.md
```

## How It Works

1. The Reporting Lambda is invoked manually.
2. It sends an HTTPS request to API Gateway.
3. API Gateway invokes the Mock API Lambda.
4. The Mock API Lambda returns sample incident records.
5. The Reporting Lambda calculates incident statistics.
6. The report is uploaded to Amazon S3 as JSON.

## Sample Report

```json
{
  "total_incidents": 3,
  "open_incidents": 2,
  "high_priority_incidents": 2
}
```

The report is stored at:

`reports/latest-report.json`

## Infrastructure as Code

AWS infrastructure is managed using Terraform.

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

The Terraform configuration provisions the S3 bucket, IAM permissions, Lambda functions, API Gateway integration, route, and deployment stage.

## Testing

Test the incident API:

```bash
curl https://<api-id>.execute-api.<region>.amazonaws.com/api/incidents
```

Invoke the Reporting Lambda:

```bash
aws lambda invoke \
  --function-name serverless-ops-report-generator \
  --region ap-south-1 \
  /tmp/lambda-response.json
```

View the response:

```bash
cat /tmp/lambda-response.json
```

Verify the generated report in S3:

```bash
aws s3 cp s3://<bucket-name>/reports/latest-report.json -
```

## Validation Results

- API Gateway returned HTTP 200.
- Mock API Lambda returned three sample incidents.
- Reporting Lambda generated the expected summary.
- JSON report was successfully uploaded to Amazon S3.
- Infrastructure was provisioned using Terraform.

## Skills Demonstrated

- AWS serverless architecture
- REST API integration
- Python automation
- Terraform infrastructure provisioning
- IAM permissions and least-privilege concepts
- Amazon S3 object storage
- AWS CLI testing and troubleshooting

## Future Improvements

- Schedule report generation using Amazon EventBridge.
- Add CloudWatch alarms and notifications.
- Integrate with a real incident management API.
- Add automated tests and CI/CD deployment.
- Improve IAM permission isolation between Lambda functions.
