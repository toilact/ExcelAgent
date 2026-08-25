# Project Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a reproducible FastAPI/React health slice with the approved localhost trust boundary, one-command native development startup, and CI quality gates.

**Architecture:** FastAPI owns the local HTTP boundary and exposes health/bootstrap endpoints. React performs the one-time fragment-to-cookie bootstrap before showing backend health. Locked Python/npm projects and a root script provide deterministic local and CI workflows without introducing Excel, OpenAI, persistence, or domain contracts early.

**Tech Stack:** Python 3.12, uv 0.11+, FastAPI, Pydantic Settings, pytest, Ruff, mypy, Node.js 24 LTS (local compatibility range 24–26), npm 11, React, TypeScript, Vite, Vitest, Testing Library, ESLint, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-08-25-excel-agent-mvp-design.md`

## Global Constraints

- Work only on Roadmap Session 2, branch `chore/project-foundation`; do not add Excel, OpenAI, SQLite, workbook domain, or session APIs.
- Backend requires Python `>=3.12,<3.13`, uses a `src/` package layout, and binds to `127.0.0.1:8000`.
- Frontend supports Node `>=24,<27`, runs on `127.0.0.1:5173`, and proxies `/api` to the backend with the upstream Host rewritten to `127.0.0.1:8000`.
- Local HTTP protection must enforce the configured API Host and UI Origin. A one-time 256-bit launch token is exchanged for an `HttpOnly; SameSite=Strict; Path=/` cookie; the token is removed from the fragment before the request and never logged or persisted.
- `/api/health` is the only unauthenticated API read. `/api/bootstrap` is the only unauthenticated mutation; every other `/api/*` request requires the local session cookie.
- CORS uses one exact configured origin with credentials and never uses a wildcard.
- Commit `backend/uv.lock` and `frontend/package-lock.json`. CI uses the lockfiles without updating them.
- Follow RED → verify expected failure → GREEN → full task suite. Tests assert observable behavior rather than framework internals or source text.
- Conventional Commit messages are short and in English. Each task ends in one focused commit.

## File Map

- `backend/src/excel_agent/api/app.py`: FastAPI factory, routes, CORS, and middleware assembly.
- `backend/src/excel_agent/api/settings.py`: environment-backed local runtime settings.
- `backend/src/excel_agent/api/local_auth.py`: one-time token exchange and cookie-session checks.
- `backend/tests/unit/api/`: health and local trust boundary behavior.
- `frontend/src/shared/api/bootstrap.ts`: fragment removal, token exchange, and health request.
- `frontend/src/features/health/`: health screen and component tests.
- `scripts/dev`: native backend/frontend lifecycle and browser launch.
- `scripts/check`: canonical local/CI quality gate.
- `.github/workflows/ci.yml`: locked Python/Node CI environment.

---

### Task 1: FastAPI health service and Python toolchain

**Files:**
- Create: `backend/.python-version`
- Create: `backend/pyproject.toml`
- Create: `backend/uv.lock`
- Create: `backend/src/excel_agent/__init__.py`
- Create: `backend/src/excel_agent/api/__init__.py`
- Create: `backend/src/excel_agent/api/app.py`
- Create: `backend/tests/unit/api/test_health.py`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `create_app() -> fastapi.FastAPI`
- Produces: `GET /api/health -> 200 {"status":"ok","service":"excel-agent-api"}`
- Consumes: no application interfaces; this is the first code task.

- [ ] **Step 1: Create the locked Python project configuration**

Run:

```bash
uv init --package --name excel-agent --python 3.12 --no-readme --author-from none --vcs none backend
uv add --project backend fastapi 'uvicorn[standard]' pydantic-settings
uv add --project backend --dev httpx pytest pytest-cov ruff mypy
```

Set these exact tool policies in `backend/pyproject.toml` and retain the dependency versions written by `uv add`:

```toml
[project]
name = "excel-agent"
version = "0.1.0"
requires-python = ">=3.12,<3.13"

[tool.pytest.ini_options]
addopts = "-q --strict-markers --cov=excel_agent --cov-report=term-missing --cov-fail-under=90"
testpaths = ["tests"]

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]

[tool.mypy]
python_version = "3.12"
strict = true
packages = ["excel_agent"]
plugins = ["pydantic.mypy"]
```

Add only generated/local outputs to `.gitignore`:

```gitignore
backend/.venv/
backend/.coverage
backend/htmlcov/
backend/.pytest_cache/
backend/.mypy_cache/
backend/.ruff_cache/
```

- [ ] **Step 2: Write the failing health test**

Create `backend/tests/unit/api/test_health.py`:

```python
from fastapi.testclient import TestClient

from excel_agent.api.app import create_app


def test_health_reports_ready_service() -> None:
    client = TestClient(create_app(), base_url="http://127.0.0.1:8000")

    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "excel-agent-api"}
```

- [ ] **Step 3: Run RED and confirm the missing application failure**

Run:

```bash
uv --directory backend run pytest tests/unit/api/test_health.py -q
```

Expected: FAIL during collection because `excel_agent.api.app` does not exist. A dependency/configuration error is not an acceptable RED; fix project setup until the failure names the missing module.

- [ ] **Step 4: Implement the minimal app factory**

Create `backend/src/excel_agent/api/app.py`:

```python
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
```

Keep both package `__init__.py` files empty.

- [ ] **Step 5: Run GREEN and Python quality gates**

Run:

```bash
uv --directory backend run pytest tests/unit/api/test_health.py -q
uv --directory backend run ruff check .
uv --directory backend run mypy src tests
uv --directory backend lock --check
```

Expected: health test passes, coverage is at least 90%, and all other commands exit 0 with no warnings.

- [ ] **Step 6: Commit Task 1**

```bash
git add .gitignore backend
git commit -m "chore: scaffold FastAPI health service"
```

---

### Task 2: Local HTTP trust boundary

**Files:**
- Create: `backend/src/excel_agent/api/settings.py`
- Create: `backend/src/excel_agent/api/local_auth.py`
- Create: `backend/tests/unit/api/test_local_trust.py`
- Modify: `backend/src/excel_agent/api/app.py`
- Modify: `backend/tests/unit/api/test_health.py`

**Interfaces:**
- Produces: `Settings(api_host, api_port, ui_origin, launch_token)` with `allowed_host: str`
- Produces: `LocalSessionAuth.exchange_launch_token(token: str) -> str | None`
- Produces: `LocalSessionAuth.is_session_valid(token: str | None) -> bool`
- Changes: `create_app(settings: Settings | None = None, auth: LocalSessionAuth | None = None) -> FastAPI`
- Produces: `POST /api/bootstrap -> 204` and cookie `excelagent_local_session`
- Consumes: Task 1 health factory and FastAPI project.

- [ ] **Step 1: Write failing trust-boundary tests**

Create `backend/tests/unit/api/test_local_trust.py` with a helper that uses literal secrets, never production token generation:

```python
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
```

Add one test proving a trusted CORS preflight returns only `Access-Control-Allow-Origin: http://127.0.0.1:5173` with credentials, and one test proving an unsafe request without `Origin` succeeds only when its `Referer` has that exact scheme and authority.

Update the health test to construct `Settings` and `LocalSessionAuth`, proving health remains public under the middleware.

- [ ] **Step 2: Run RED and confirm missing trust modules**

```bash
uv --directory backend run pytest tests/unit/api/test_local_trust.py -q
```

Expected: FAIL during collection because `settings` or `local_auth` does not exist.

- [ ] **Step 3: Implement settings and one-time session auth**

Implement `Settings` with `SettingsConfigDict(env_prefix="EXCEL_AGENT_")`, defaults `127.0.0.1`, `8000`, and `http://127.0.0.1:5173`, plus required `launch_token: SecretStr`. `allowed_host` returns `f"{api_host}:{api_port}"`.

```python
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
```

Implement `LocalSessionAuth` with a `threading.Lock`, `secrets.token_urlsafe(32)` as the default session-token factory, and `secrets.compare_digest`. `exchange_launch_token` returns the session token exactly once for a matching launch token and returns `None` otherwise. `is_session_valid` performs a constant-time comparison and accepts `None` safely.

Use this exact cookie name in one exported constant:

```python
LOCAL_SESSION_COOKIE = "excelagent_local_session"
```

Use this complete state transition:

```python
from collections.abc import Callable
import secrets
from threading import Lock

LOCAL_SESSION_COOKIE = "excelagent_local_session"


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
            if self._launch_consumed or not secrets.compare_digest(token, self._launch_token):
                return None
            self._launch_consumed = True
            return self._session_token

    def is_session_valid(self, token: str | None) -> bool:
        return token is not None and secrets.compare_digest(token, self._session_token)
```

- [ ] **Step 4: Assemble middleware, CORS, and bootstrap route**

Change the factory signature to:

```python
def create_app(
    settings: Settings | None = None,
    auth: LocalSessionAuth | None = None,
) -> FastAPI:
```

When arguments are absent, load `Settings()` and create `LocalSessionAuth` from its secret. Add exact-origin credentialed CORS. Add middleware with these ordered rules:

1. Reject every request whose `Host` differs from `settings.allowed_host` with 400.
2. Allow `/api/health` after the Host check.
3. For unsafe methods, require either exact `Origin == settings.ui_origin` or a `Referer` whose scheme and authority equal that origin; otherwise 403.
4. Allow `/api/bootstrap` to reach its route after the Host/origin checks.
5. For every other `/api/*`, require a valid `LOCAL_SESSION_COOKIE`; otherwise 401.
6. Pass non-API paths through after the Host check.

The bootstrap route reads `X-ExcelAgent-Launch-Token`, returns 401 on invalid/reused tokens, and on success returns 204 with:

```python
response.set_cookie(
    key=LOCAL_SESSION_COOKIE,
    value=session_token,
    httponly=True,
    samesite="strict",
    secure=False,
    path="/",
)
```

Do not log headers, tokens, or cookies.

Implement the middleware and routes with this control flow; small import/layout adjustments are allowed only to satisfy Ruff/mypy:

```python
from collections.abc import Awaitable, Callable
from urllib.parse import urlsplit

from fastapi import FastAPI, Header, HTTPException, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from starlette.responses import JSONResponse

from excel_agent.api.local_auth import LOCAL_SESSION_COOKIE, LocalSessionAuth
from excel_agent.api.settings import Settings


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

    # Register CORS after the local middleware so CORS is the outer wrapper
    # and trusted browser clients can read local-boundary error responses.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[resolved_settings.ui_origin],
        allow_credentials=True,
        allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "X-ExcelAgent-Launch-Token"],
    )

    @app.get("/api/health", response_model=HealthResponse)
    async def health() -> HealthResponse:
        return HealthResponse()

    @app.post("/api/bootstrap", status_code=status.HTTP_204_NO_CONTENT)
    async def bootstrap(
        response: Response,
        launch_token: str = Header(alias="X-ExcelAgent-Launch-Token"),
    ) -> None:
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
```

- [ ] **Step 5: Run GREEN plus boundary-focused coverage**

```bash
uv --directory backend run pytest tests/unit/api/test_health.py tests/unit/api/test_local_trust.py -q
uv --directory backend run ruff check .
uv --directory backend run mypy src tests
```

Expected: all tests pass with coverage at least 90%; lint and type checks exit 0 with pristine output.

- [ ] **Step 6: Commit Task 2**

```bash
git add backend/src backend/tests
git commit -m "feat: enforce local HTTP trust boundary"
```

---

### Task 3: React bootstrap and health screen

**Files:**
- Create: `frontend/package.json`
- Create: `frontend/package-lock.json`
- Create: `frontend/tsconfig.json`
- Create: `frontend/tsconfig.app.json`
- Create: `frontend/tsconfig.node.json`
- Create: `frontend/vite.config.ts`
- Create: `frontend/eslint.config.js`
- Create: `frontend/index.html`
- Create: `frontend/src/main.tsx`
- Create: `frontend/src/shared/api/bootstrap.ts`
- Create: `frontend/src/features/health/App.tsx`
- Create: `frontend/src/features/health/App.test.tsx`
- Create: `frontend/src/test/setup.ts`
- Create: `frontend/src/styles.css`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `bootstrapLocalSession(): Promise<HealthResponse>`
- Produces: `HealthResponse = {status: "ok"; service: "excel-agent-api"}`
- Produces: `App` states `Connecting…`, `ExcelAgent is ready`, and a Vietnamese failure message.
- Consumes: Task 2 `POST /api/bootstrap`, cookie session, and Task 1 `GET /api/health`.

- [ ] **Step 1: Create only frontend package/tool configuration**

Initialize npm without generating application code:

```bash
mkdir -p frontend/src/features/health frontend/src/shared/api frontend/src/test
cd frontend
npm init -y
npm install react react-dom
npm install --save-dev vite @vitejs/plugin-react typescript @types/node @types/react @types/react-dom vitest @vitest/coverage-v8 jsdom @testing-library/react @testing-library/jest-dom eslint @eslint/js typescript-eslint globals eslint-plugin-react-hooks eslint-plugin-react-refresh
```

Set `packageManager` to `npm@11.16.0`, engines to `node >=24 <27`, and exact scripts:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "typecheck": "tsc -b --pretty false",
    "test": "vitest run --coverage"
  }
}
```

Configure Vite at `127.0.0.1:5173`; proxy `/api` to `http://127.0.0.1:8000` with `changeOrigin: true`. Configure Vitest for `jsdom`, `src/test/setup.ts`, and V8 coverage thresholds of 90% for lines, functions, branches, and statements. Configure TypeScript with strict mode and no emit. Configure ESLint for TypeScript, React Hooks, and React Refresh while ignoring `dist` and `coverage`.

Use this Vite/Vitest boundary:

```typescript
import react from "@vitejs/plugin-react";
import {defineConfig} from "vitest/config";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
    proxy: {
      "/api": {target: "http://127.0.0.1:8000", changeOrigin: true},
    },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["src/test/setup.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text"],
      thresholds: {lines: 90, functions: 90, branches: 90, statements: 90},
    },
  },
});
```

Add `frontend/node_modules/`, `frontend/dist/`, and `frontend/coverage/` to `.gitignore`.

- [ ] **Step 2: Write failing bootstrap and UI tests**

Create tests covering real observable behavior:

```tsx
import {render, screen} from "@testing-library/react";
import {beforeEach, expect, test, vi} from "vitest";

import {App} from "./App";
import {bootstrapLocalSession} from "../../shared/api/bootstrap";

beforeEach(() => {
  window.history.replaceState(null, "", "/#token=launch-secret");
  vi.restoreAllMocks();
});

test("removes the launch token before exchanging it", async () => {
  const request = vi
    .fn<typeof fetch>()
    .mockResolvedValueOnce(new Response(null, {status: 204}))
    .mockResolvedValueOnce(
      new Response(JSON.stringify({status: "ok", service: "excel-agent-api"}), {
        status: 200,
        headers: {"content-type": "application/json"},
      }),
    );

  await bootstrapLocalSession(request);

  expect(window.location.hash).toBe("");
  expect(request).toHaveBeenNthCalledWith(
    1,
    "/api/bootstrap",
    expect.objectContaining({
      method: "POST",
      credentials: "include",
      headers: {"X-ExcelAgent-Launch-Token": "launch-secret"},
    }),
  );
});

test("shows ready after local bootstrap and health succeed", async () => {
  vi.spyOn(globalThis, "fetch")
    .mockResolvedValueOnce(new Response(null, {status: 204}))
    .mockResolvedValueOnce(
      new Response(JSON.stringify({status: "ok", service: "excel-agent-api"}), {
        status: 200,
        headers: {"content-type": "application/json"},
      }),
    );

  render(<App />);

  expect(screen.getByText("Connecting to ExcelAgent…")).toBeInTheDocument();
  expect(await screen.findByText("ExcelAgent is ready")).toBeInTheDocument();
});
```

Add a third test that returns a 401 bootstrap response and asserts the rendered message `Không thể kết nối ExcelAgent.`.

Add a fourth bootstrap test with no fragment that asserts only the credentialed health GET occurs, and a fifth UI test with a non-OK health response that asserts the same Vietnamese error state. These branches are required for the 90% coverage gate.

- [ ] **Step 3: Run RED and confirm missing application modules**

```bash
npm --prefix frontend test
```

Expected: FAIL because `App` or `bootstrapLocalSession` is missing. Resolve only config/test-environment errors until the failure names missing production modules.

- [ ] **Step 4: Implement bootstrap behavior and health UI**

`bootstrapLocalSession(request = globalThis.fetch)` must:

1. Read `token` from `window.location.hash`.
2. Immediately call `history.replaceState(null, "", pathname + search)` before any network request.
3. If token exists, POST `/api/bootstrap` with `credentials: "include"` and only the `X-ExcelAgent-Launch-Token` header; throw on non-204.
4. GET `/api/health` with `credentials: "include"`; validate `response.ok` and the literal JSON shape before returning it.
5. Never log or store the token.

Use this implementation shape:

```typescript
export type HealthResponse = {
  status: "ok";
  service: "excel-agent-api";
};

function isHealthResponse(value: unknown): value is HealthResponse {
  if (typeof value !== "object" || value === null) return false;
  const candidate = value as Record<string, unknown>;
  return candidate.status === "ok" && candidate.service === "excel-agent-api";
}

export async function bootstrapLocalSession(
  request: typeof fetch = globalThis.fetch,
): Promise<HealthResponse> {
  const token = new URLSearchParams(window.location.hash.slice(1)).get("token");
  window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);

  if (token !== null) {
    const bootstrap = await request("/api/bootstrap", {
      method: "POST",
      credentials: "include",
      headers: {"X-ExcelAgent-Launch-Token": token},
    });
    if (bootstrap.status !== 204) throw new Error("Local bootstrap failed");
  }

  const response = await request("/api/health", {credentials: "include"});
  if (!response.ok) throw new Error("Health request failed");
  const health: unknown = await response.json();
  if (!isHealthResponse(health)) throw new Error("Invalid health response");
  return health;
}
```

`App` starts in connecting state, calls bootstrap once in an effect, and renders the English ready state on success and exact Vietnamese error text on failure. `main.tsx` mounts one `App` without React `StrictMode`: development double-effect execution would race the deliberately one-time bootstrap exchange. Keep CSS limited to a centered, accessible health card with system fonts and light/dark color support; no chat UI is in scope.

```tsx
import {useEffect, useState} from "react";

import {bootstrapLocalSession} from "../../shared/api/bootstrap";

type ConnectionState = "connecting" | "ready" | "failed";

export function App() {
  const [state, setState] = useState<ConnectionState>("connecting");

  useEffect(() => {
    let active = true;
    void bootstrapLocalSession()
      .then(() => active && setState("ready"))
      .catch(() => active && setState("failed"));
    return () => {
      active = false;
    };
  }, []);

  return (
    <main>
      <section aria-live="polite">
        <p className="eyebrow">Local workspace</p>
        <h1>ExcelAgent</h1>
        {state === "connecting" && <p>Connecting to ExcelAgent…</p>}
        {state === "ready" && <p>ExcelAgent is ready</p>}
        {state === "failed" && <p role="alert">Không thể kết nối ExcelAgent.</p>}
      </section>
    </main>
  );
}
```

- [ ] **Step 5: Run GREEN and frontend quality gates**

```bash
npm --prefix frontend test
npm --prefix frontend run lint
npm --prefix frontend run typecheck
npm --prefix frontend run build
```

Expected: tests pass at 90% thresholds, lint/typecheck exit 0, and Vite produces `frontend/dist` without warnings.

- [ ] **Step 6: Commit Task 3**

```bash
git add .gitignore frontend
git commit -m "feat: add local bootstrap health screen"
```

---

### Task 4: One-command development workflow and CI

**Files:**
- Create: `scripts/dev`
- Create: `scripts/check`
- Create: `scripts/tests/dev-smoke.sh`
- Create: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `docs/runbook.md`
- Modify: `docs/testing.md`

**Interfaces:**
- Produces: `./scripts/dev [--no-open]` starts backend and frontend, waits for readiness, and opens the fragment bootstrap URL unless disabled.
- Produces: `./scripts/check` runs the canonical locked quality gate.
- Consumes: Task 1/2 uvicorn factory and health endpoint; Task 3 npm scripts and Vite proxy.

- [ ] **Step 1: Write the failing executable smoke test**

Create `scripts/tests/dev-smoke.sh` first. It must start `./scripts/dev --no-open` in the background, register a trap that terminates and waits for the launcher, poll both `http://127.0.0.1:8000/api/health` and `http://127.0.0.1:5173/` for at most 30 seconds, assert the health JSON contains `excel-agent-api`, and exit non-zero on timeout.

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
launcher_pid=""
cleanup() {
  [[ -n $launcher_pid ]] && kill "$launcher_pid" 2>/dev/null || true
  [[ -n $launcher_pid ]] && wait "$launcher_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

"$repo_root/scripts/dev" --no-open &
launcher_pid=$!
health=""
ui_ready=0
for _ in {1..120}; do
  health=$(curl -fsS http://127.0.0.1:8000/api/health 2>/dev/null || true)
  if [[ $health == *'"service":"excel-agent-api"'* ]] && \
    curl -fsS http://127.0.0.1:5173/ >/dev/null 2>&1; then
    ui_ready=1
    break
  fi
  kill -0 "$launcher_pid" 2>/dev/null || break
  sleep 0.25
done

[[ $ui_ready -eq 1 ]] || { echo "Development smoke test timed out" >&2; exit 1; }
[[ $health == *'"status":"ok"'* ]]
```

Run:

```bash
bash scripts/tests/dev-smoke.sh
```

Expected: FAIL with `./scripts/dev: No such file or directory`.

- [ ] **Step 2: Implement the native launcher**

Create executable `scripts/dev` with `set -euo pipefail`. It must:

- accept only optional `--no-open`, otherwise print usage and exit 2;
- verify `uv`, `npm`, `curl`, `openssl`, and on normal macOS launch `open` are available;
- generate `EXCEL_AGENT_LAUNCH_TOKEN` with `openssl rand -hex 32` and never print it;
- start `uv --directory backend run uvicorn excel_agent.api.app:create_app --factory --host 127.0.0.1 --port 8000` with the token exported;
- start `npm --prefix frontend run dev -- --host 127.0.0.1 --port 5173`;
- trap EXIT, INT, and TERM, terminating and waiting for both child processes;
- poll `/api/health` for at most 30 seconds;
- run `open "http://127.0.0.1:5173/#token=${EXCEL_AGENT_LAUNCH_TOKEN}"` unless `--no-open`;
- resolve the repository root from the script location so the command works from any current directory;
- use a Bash 3.2-compatible `kill -0` polling loop (not `wait -n`) to detect an unexpected child exit and return non-zero.

Do not enable shell tracing and do not place the token in output files.

Use this complete Bash 3.2-compatible structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
no_open=0
if [[ ${1:-} == "--no-open" ]]; then
  no_open=1
  shift
fi
if [[ $# -ne 0 ]]; then
  echo "Usage: ./scripts/dev [--no-open]" >&2
  exit 2
fi

for required_command in uv npm curl openssl; do
  command -v "$required_command" >/dev/null || {
    echo "Missing required command: $required_command" >&2
    exit 1
  }
done
if [[ $no_open -eq 0 ]]; then
  command -v open >/dev/null || { echo "Missing required command: open" >&2; exit 1; }
fi

export EXCEL_AGENT_LAUNCH_TOKEN
EXCEL_AGENT_LAUNCH_TOKEN=$(openssl rand -hex 32)
backend_pid=""
frontend_pid=""

cleanup() {
  [[ -n $backend_pid ]] && kill "$backend_pid" 2>/dev/null || true
  [[ -n $frontend_pid ]] && kill "$frontend_pid" 2>/dev/null || true
  [[ -n $backend_pid ]] && wait "$backend_pid" 2>/dev/null || true
  [[ -n $frontend_pid ]] && wait "$frontend_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT TERM

uv --directory "$repo_root/backend" run uvicorn excel_agent.api.app:create_app \
  --factory --host 127.0.0.1 --port 8000 &
backend_pid=$!
npm --prefix "$repo_root/frontend" run dev -- --host 127.0.0.1 --port 5173 &
frontend_pid=$!

ready=0
for _ in {1..120}; do
  if curl -fsS http://127.0.0.1:8000/api/health >/dev/null; then
    ready=1
    break
  fi
  kill -0 "$backend_pid" 2>/dev/null || break
  kill -0 "$frontend_pid" 2>/dev/null || break
  sleep 0.25
done
[[ $ready -eq 1 ]] || { echo "ExcelAgent services did not become ready" >&2; exit 1; }

if [[ $no_open -eq 0 ]]; then
  open "http://127.0.0.1:5173/#token=${EXCEL_AGENT_LAUNCH_TOKEN}"
fi

while kill -0 "$backend_pid" 2>/dev/null && kill -0 "$frontend_pid" 2>/dev/null; do
  sleep 1
done
echo "An ExcelAgent development service stopped unexpectedly" >&2
exit 1
```

- [ ] **Step 3: Run GREEN for the development smoke test**

```bash
chmod +x scripts/dev scripts/tests/dev-smoke.sh
bash -n scripts/dev scripts/tests/dev-smoke.sh
bash scripts/tests/dev-smoke.sh
```

Expected: syntax checks pass; smoke test reaches both services within 30 seconds, validates health JSON, and cleans up child processes.

- [ ] **Step 4: Add the canonical check script and CI workflow**

Create executable `scripts/check` with `set -euo pipefail` and these commands in order:

```bash
uv --directory backend lock --check
uv --directory backend run ruff check .
uv --directory backend run mypy src tests
uv --directory backend run pytest
npm --prefix frontend run lint
npm --prefix frontend run typecheck
npm --prefix frontend test
npm --prefix frontend run build
bash -n scripts/dev scripts/check scripts/tests/dev-smoke.sh
```

Resolve `repo_root` exactly as in `scripts/dev` and `cd "$repo_root"` before these commands so the gate works from any directory.

Create `.github/workflows/ci.yml` with `permissions: contents: read`, triggers for pushes to `main` and pull requests, and one Ubuntu quality job. Pin actions exactly:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
- uses: astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9 # v9.0.0
  with:
    python-version: "3.12"
    enable-cache: true
- uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
  with:
    node-version: "24"
    cache: npm
    cache-dependency-path: frontend/package-lock.json
```

The job runs `uv --directory backend sync --locked`, `npm --prefix frontend ci`, then `./scripts/check`. It does not run the dev smoke test because that test starts long-lived services; the smoke remains a mandatory local gate for this PR.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9 # v9.0.0
        with:
          python-version: "3.12"
          enable-cache: true
      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version: "24"
          cache: npm
          cache-dependency-path: frontend/package-lock.json
      - run: uv --directory backend sync --locked
      - run: npm --prefix frontend ci
      - run: ./scripts/check
```

- [ ] **Step 5: Update operator and test documentation**

Update README and runbook with exact prerequisites and commands:

```bash
uv --directory backend sync --locked
npm --prefix frontend ci
./scripts/dev
./scripts/check
bash scripts/tests/dev-smoke.sh
```

Document that the launcher opens a fragment containing a one-time token, the frontend removes it before exchange, and no API key is needed in Session 2. Update `docs/testing.md` to name `./scripts/check` as the automated PR gate and the smoke command as Session 2 local evidence.

- [ ] **Step 6: Run the complete Session 2 gate**

```bash
./scripts/check
bash scripts/tests/dev-smoke.sh
git diff --check
```

Expected: every command exits 0; Python and frontend coverage meet 90%; smoke reaches both services and cleans up; Git reports no whitespace errors.

- [ ] **Step 7: Commit Task 4**

```bash
git add .github README.md docs scripts
git commit -m "ci: add reproducible development workflow"
```

## Plan Self-Review Checklist

- Task 1 owns Python packaging and the public health response consumed by Tasks 2–4.
- Task 2 owns every approved local HTTP trust control before other stateful APIs exist.
- Task 3 consumes only the health/bootstrap contracts and adds no chat or workbook functionality.
- Task 4 consumes both locked projects and defines the single local/CI command surface.
- Every production behavior has a named RED command and observable GREEN assertion; generated lockfiles/configuration are setup artifacts rather than behavior under test.
- No placeholder, deferred implementation, undefined interface, or out-of-session feature remains.
