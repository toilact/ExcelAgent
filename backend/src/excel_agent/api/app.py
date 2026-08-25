from collections.abc import Awaitable, Callable
from typing import Literal
from urllib.parse import urlsplit

from fastapi import FastAPI, Header, HTTPException, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from starlette.responses import JSONResponse

from excel_agent.api.local_auth import LOCAL_SESSION_COOKIE, LocalSessionAuth
from excel_agent.api.settings import Settings


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: Literal["excel-agent-api"] = "excel-agent-api"


def _browser_source_is_trusted(request: Request, ui_origin: str) -> bool:
    origin = request.headers.get("origin")
    if origin is not None:
        return origin == ui_origin
    referer = request.headers.get("referer")
    if referer is None:
        return False
    parsed = urlsplit(referer)
    return f"{parsed.scheme}://{parsed.netloc}" == ui_origin


def create_app(
    settings: Settings | None = None,
    auth: LocalSessionAuth | None = None,
) -> FastAPI:
    resolved_settings = settings or Settings()
    resolved_auth = auth or LocalSessionAuth(
        resolved_settings.launch_token.get_secret_value(),
    )
    app = FastAPI(title="ExcelAgent API", version="0.1.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=[resolved_settings.ui_origin],
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "X-ExcelAgent-Launch-Token"],
    )

    @app.middleware("http")
    async def enforce_local_trust(
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]],
    ) -> Response:
        if request.headers.get("host") != resolved_settings.allowed_host:
            return JSONResponse({"detail": "Untrusted host"}, status_code=400)
        if request.url.path == "/api/health" or request.method == "OPTIONS":
            return await call_next(request)
        if request.method not in {"GET", "HEAD"} and not _browser_source_is_trusted(
            request,
            resolved_settings.ui_origin,
        ):
            return JSONResponse({"detail": "Untrusted browser origin"}, status_code=403)
        if request.url.path == "/api/bootstrap":
            return await call_next(request)
        if request.url.path.startswith("/api/") and not resolved_auth.is_session_valid(
            request.cookies.get(LOCAL_SESSION_COOKIE),
        ):
            return JSONResponse({"detail": "Local session required"}, status_code=401)
        return await call_next(request)

    @app.get("/api/health", response_model=HealthResponse)
    async def health() -> HealthResponse:
        return HealthResponse()

    @app.post("/api/bootstrap", status_code=status.HTTP_204_NO_CONTENT)
    async def bootstrap(
        response: Response,
        launch_token: str | None = Header(default=None, alias="X-ExcelAgent-Launch-Token"),
    ) -> None:
        if launch_token is None:
            raise HTTPException(status_code=401, detail="Invalid launch token")
        session_token = resolved_auth.exchange_launch_token(launch_token)
        if session_token is None:
            raise HTTPException(status_code=401, detail="Invalid launch token")
        response.set_cookie(
            key=LOCAL_SESSION_COOKIE,
            value=session_token,
            httponly=True,
            samesite="strict",
            secure=False,
            path="/",
        )

    return app
