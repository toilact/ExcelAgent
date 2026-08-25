from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel


class HealthResponse(BaseModel):
    status: Literal["ok"] = "ok"
    service: Literal["excel-agent-api"] = "excel-agent-api"


def create_app() -> FastAPI:
    app = FastAPI(title="ExcelAgent API", version="0.1.0")

    @app.get("/api/health", response_model=HealthResponse)
    async def health() -> HealthResponse:
        return HealthResponse()

    return app
