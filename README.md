# ExcelAgent

ExcelAgent is a local-first macOS web application that turns Vietnamese office-work requests into reviewed, typed workbook operations. OpenAI plans the work; a deterministic Python adapter executes approved operations through Microsoft Excel without overwriting the uploaded source.

The project foundation provides a local FastAPI health service, a React health screen, and a one-command development workflow.

## Local development

Prerequisites are macOS, Python 3.12 with `uv` >= 0.11, Node.js >= 24 and < 27 with npm 11, `curl`, `openssl`, and the macOS `open` command. Microsoft Excel is not exercised by the Session 2 foundation, and no OpenAI API key is needed yet.

Install the locked dependencies:

```bash
uv --directory backend sync --locked
npm --prefix frontend ci
```

From the repository root, start the backend and frontend with:

```bash
./scripts/dev
```

The script resolves the repository root internally, so it also works from another current directory when invoked through a path to `scripts/dev`.

The launcher opens the UI with a one-time token in the URL fragment. The frontend removes the fragment before exchanging the token for the local session cookie. The token is not written to application logs or files.

From the repository root, run the automated PR gate and the Session 2 local smoke test with:

```bash
./scripts/check
bash scripts/tests/dev-smoke.sh
```

## Documentation

- [MVP design](docs/superpowers/specs/2026-08-25-excel-agent-mvp-design.md)
- [Architecture map](docs/architecture.md)
- [Session roadmap](docs/roadmap.md)
- [Testing and evidence](docs/testing.md)
- [macOS and Excel runbook](docs/runbook.md)
- [Agent instructions](AGENTS.md)

## Current constraints

- Single user with no user accounts; local access uses per-launch authorization.
- Native macOS runtime; Docker and Windows support are outside the MVP.
- Inputs are chat, `.xlsx`, and `.csv`.
- Macro/UDF injection, arbitrary code, and external data connections are outside the MVP.
