from fastapi.testclient import TestClient
from pydantic import SecretStr

from excel_agent.api.app import create_app
from excel_agent.api.local_auth import LocalSessionAuth
from excel_agent.api.settings import Settings

LAUNCH_TOKEN = "health-launch-token-for-tests"
SESSION_TOKEN = "health-session-token-for-tests"


def test_health_reports_ready_service() -> None:
    settings = Settings(launch_token=SecretStr(LAUNCH_TOKEN))
    auth = LocalSessionAuth(LAUNCH_TOKEN, session_token_factory=lambda: SESSION_TOKEN)
    client = TestClient(
        create_app(settings=settings, auth=auth),
        base_url="http://127.0.0.1:8000",
    )

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "excel-agent-api"}
