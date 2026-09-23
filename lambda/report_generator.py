import json
import requests

API_URL = "http://localhost:5000/api/incidents"

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

if __name__ == "__main__":
    incidents = fetch_incidents()
    summary = generate_summary(incidents)
    save_json_report(summary)
    print(summary)
