import secrets
from collections.abc import Callable
from threading import Lock

LOCAL_SESSION_COOKIE = "excelagent_local_session"


def _tokens_match(candidate: str, expected: str) -> bool:
    return secrets.compare_digest(candidate.encode(), expected.encode())


class LocalSessionAuth:
    def __init__(
        self,
        launch_token: str,
        session_token_factory: Callable[[], str] | None = None,
    ) -> None:
        self._launch_token = launch_token
        self._session_token = (session_token_factory or (lambda: secrets.token_urlsafe(32)))()
        self._launch_consumed = False
        self._lock = Lock()

    def exchange_launch_token(self, token: str) -> str | None:
        with self._lock:
            if self._launch_consumed or not _tokens_match(token, self._launch_token):
                return None
            self._launch_consumed = True
            return self._session_token

    def is_session_valid(self, token: str | None) -> bool:
        return token is not None and _tokens_match(token, self._session_token)
