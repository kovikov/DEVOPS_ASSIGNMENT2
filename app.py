import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)


def get_env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


@app.get("/")
def index():
    hostname = socket.gethostname()
    db_host = get_env("DB_HOST", "not-set")
    db_name = get_env("DB_NAME", "lampdb")
    db_user = get_env("DB_USER", "lampuser")

    html = f"""
    <html>
      <head><title>LAMP Stack Demo App</title></head>
      <body style=\"font-family: Arial, sans-serif; margin: 2rem;\">
        <h1>LAMP Stack Demo App</h1>
        <p><strong>Server Hostname:</strong> {hostname}</p>
        <p><strong>App Status:</strong> Server is running!</p>
        <p><strong>DB Host:</strong> {db_host}</p>
        <p><strong>DB Name:</strong> {db_name}</p>
        <p><strong>DB User:</strong> {db_user}</p>
      </body>
    </html>
    """
    return html, 200


@app.get("/health")
def health():
    hostname = socket.gethostname()
    db_host = get_env("DB_HOST", "not-set")
    db_name = get_env("DB_NAME", "lampdb")

    return jsonify(
        {
            "status": "healthy",
            "hostname": hostname,
            "database": f"Configured for {db_name} at {db_host}",
        }
    ), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
