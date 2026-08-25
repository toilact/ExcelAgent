# ADR-0002: Native macOS runtime

- Status: Accepted
- Date: 2026-08-25

## Decision

Run FastAPI and Excel automation natively on macOS using `uv`. The browser UI connects only to `127.0.0.1`. Docker and Windows support are deferred.

## Consequences

- The executor can use xlwings and macOS Automation to control installed Excel.
- Local setup must verify Excel installation, Automation permission, and the absence of other open workbooks.
- CI uses fake adapters; real Excel verification runs locally before relevant PRs merge.
- Packaging as a signed macOS application is outside the MVP.

## Alternatives rejected

- Docker-only runtime: a container cannot directly own the required host Excel automation boundary.
- Docker plus host executor: adds a service protocol and lifecycle subsystem before it is needed.
- Cross-platform adapters: Windows COM would double the initial execution and E2E matrix.

