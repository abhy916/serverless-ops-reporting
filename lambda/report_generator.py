import requests

API_URL = "http://localhost:5000/api/incidents"

def fetch_incidents():
    response = requests.get(API_URL, timeout=10)
    response.raise_for_status()

    data = response.json()
    return data["result"]

if __name__ == "__main__":
    incidents = fetch_incidents()
    print(incidents)
