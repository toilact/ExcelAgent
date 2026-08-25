from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="EXCEL_AGENT_", extra="ignore")

    api_host: str = "127.0.0.1"
    api_port: int = 8000
    ui_origin: str = "http://127.0.0.1:5173"
    launch_token: SecretStr

    @property
    def allowed_host(self) -> str:
        return f"{self.api_host}:{self.api_port}"
