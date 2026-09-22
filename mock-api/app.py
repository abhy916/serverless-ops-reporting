from flask import Flask, jsonify
import json
from pathlib import Path

app = Flask(__name__)

DATA_FILE = Path(__file__).parent.parent / "sample-data" / "incidents.json"


@app.route("/api/incidents", methods=["GET"])
def get_incidents():
    with open(DATA_FILE, "r") as file:
        incidents = json.load(file)

    return jsonify({"result": incidents})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
