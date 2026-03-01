import importlib.util
import os
import pathlib
import sys


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    sys.exit(1)


repo_root = pathlib.Path(__file__).resolve().parents[2]
app_path = repo_root / "app.py"

if not app_path.exists():
    fail("app.py not found in repository root")

os.environ.setdefault("DB_HOST", "127.0.0.1")
os.environ.setdefault("DB_PORT", "3306")
os.environ.setdefault("DB_NAME", "lampdb")
os.environ.setdefault("DB_USER", "lampuser")
os.environ.setdefault("DB_PASSWORD", "testpassword")
os.environ.setdefault("FLASK_ENV", "testing")

spec = importlib.util.spec_from_file_location("app_module", app_path)
if spec is None or spec.loader is None:
    fail("failed to load app.py module")

module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

flask_app = getattr(module, "app", None)
if flask_app is None:
    fail("app.py must expose Flask instance as variable named 'app'")

client = flask_app.test_client()

for route in ("/", "/health"):
    response = client.get(route)
    print(f"GET {route} -> {response.status_code}")
    if response.status_code >= 500:
        fail(f"route {route} returned server error {response.status_code}")

print("Smoke tests passed")
