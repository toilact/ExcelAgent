from fastapi.testclient import TestClient

from excel_agent.api.app import create_app


def test_health_reports_ready_service() -> None:
    client = TestClient(create_app(), base_url="http://127.0.0.1:8000")

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "excel-agent-api"}
