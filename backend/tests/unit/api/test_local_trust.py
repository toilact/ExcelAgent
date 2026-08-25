from fastapi.testclient import TestClient
from pydantic import SecretStr

from excel_agent.api.app import create_app
from excel_agent.api.local_auth import LocalSessionAuth
from excel_agent.api.settings import Settings

LAUNCH_TOKEN = "launch-token-for-tests"
SESSION_TOKEN = "session-token-for-tests"
ORIGIN = "http://127.0.0.1:5173"


def make_client() -> TestClient:
    settings = Settings(launch_token=SecretStr(LAUNCH_TOKEN))
    auth = LocalSessionAuth(LAUNCH_TOKEN, session_token_factory=lambda: SESSION_TOKEN)
    return TestClient(
        create_app(settings=settings, auth=auth),
        base_url="http://127.0.0.1:8000",
    )


def test_rejects_untrusted_host_even_for_health() -> None:
    client = make_client()

    response = client.get("/api/health", headers={"host": "attacker.example"})

    assert response.status_code == 400


def test_rejects_untrusted_host_for_cors_preflight() -> None:
    client = make_client()

    response = client.options(
        "/api/bootstrap",
        headers={
            "host": "attacker.example",
            "origin": ORIGIN,
            "access-control-request-method": "POST",
        },
    )

    assert response.status_code == 400


def test_bootstrap_rejects_untrusted_origin() -> None:
    client = make_client()

    response = client.post(
        "/api/bootstrap",
        headers={
            "origin": "http://attacker.example",
            "x-excelagent-launch-token": LAUNCH_TOKEN,
        },
    )

    assert response.status_code == 403


def test_bootstrap_rejects_missing_launch_token() -> None:
    client = make_client()

    response = client.post("/api/bootstrap", headers={"origin": ORIGIN})

    assert response.status_code == 401


def test_bootstrap_exchanges_token_once_for_strict_cookie() -> None:
    client = make_client()
    headers = {"origin": ORIGIN, "x-excelagent-launch-token": LAUNCH_TOKEN}

    first = client.post("/api/bootstrap", headers=headers)
    second = client.post("/api/bootstrap", headers=headers)

    assert first.status_code == 204
    assert "excelagent_local_session=session-token-for-tests" in first.headers["set-cookie"]
    assert "HttpOnly" in first.headers["set-cookie"]
    assert "SameSite=strict" in first.headers["set-cookie"]
    assert "Path=/" in first.headers["set-cookie"]
    assert second.status_code == 401


def test_protected_api_requires_cookie_after_bootstrap() -> None:
    client = make_client()

    unauthenticated = client.get("/api/not-yet-implemented")
    client.post(
        "/api/bootstrap",
        headers={"origin": ORIGIN, "x-excelagent-launch-token": LAUNCH_TOKEN},
    )
    authenticated = client.get("/api/not-yet-implemented")

    assert unauthenticated.status_code == 401
    assert authenticated.status_code == 404


def test_trusted_cors_preflight_allows_only_configured_origin_with_credentials() -> None:
    client = make_client()

    response = client.options(
        "/api/bootstrap",
        headers={
            "origin": ORIGIN,
            "access-control-request-method": "POST",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == ORIGIN
    assert response.headers["access-control-allow-credentials"] == "true"


def test_unsafe_request_without_origin_requires_exact_referer_origin() -> None:
    trusted_client = make_client()
    trusted = trusted_client.post(
        "/api/bootstrap",
        headers={
            "referer": f"{ORIGIN}/",
            "x-excelagent-launch-token": LAUNCH_TOKEN,
        },
    )
    untrusted_client = make_client()
    untrusted = untrusted_client.post(
        "/api/bootstrap",
        headers={
            "referer": "https://127.0.0.1:5173/",
            "x-excelagent-launch-token": LAUNCH_TOKEN,
        },
    )

    assert trusted.status_code == 204
    assert untrusted.status_code == 403
