import json
import os
import boto3
import requests

API_URL = os.environ.get(
    "API_URL",
    "http://localhost:5000/api/incidents"
)

S3_BUCKET = os.environ.get("S3_BUCKET")

def fetch_incidents():
    response = requests.get(API_URL, timeout=10)
    response.raise_for_status()

    data = response.json()
    return data["result"]

def generate_summary(incidents):
    total_incidents = len(incidents)

    open_incidents = sum(
        1 for incident in incidents
        if incident["state"] != "Resolved"
    )

    high_priority_incidents = sum(
        1 for incident in incidents
        if incident["priority"] in ["1", "2"]
    )

    return {
        "total_incidents": total_incidents,
        "open_incidents": open_incidents,
        "high_priority_incidents": high_priority_incidents
    }

def save_json_report(summary):
    with open("report.json", "w") as file:
        json.dump(summary, file, indent=4)

def upload_report_to_s3(summary):
    if not S3_BUCKET:
        raise ValueError("S3_BUCKET environment variable is not set")

    s3 = boto3.client("s3")
    s3.put_object(
    Bucket=S3_BUCKET,
    Key="reports/latest-report.json",
    Body=json.dumps(summary, indent=4),
    ContentType="application/json"
    )

def lambda_handler(event, context):
    incidents = fetch_incidents()
    summary = generate_summary(incidents)
    upload_report_to_s3(summary)
    return {
        "statusCode": 200,
        "summary": summary
    }

if __name__ == "__main__":
    incidents = fetch_incidents()
    summary = generate_summary(incidents)
    save_json_report(summary)
    print(summary)
