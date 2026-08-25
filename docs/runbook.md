# macOS and Excel runbook

This runbook covers local runtime concerns. Feature-specific commands belong in their implementation plans.

## Supported environment

- Apple Silicon macOS.
- Microsoft Excel for Mac installed at `/Applications/Microsoft Excel.app`.
- Python 3.12 managed by `uv`.
- Node.js 22 or newer.
- OpenAI API credentials supplied through environment configuration; secrets are never committed or logged.

## Runtime policy

- Bind the web server to `127.0.0.1`.
- Run backend and Excel automation natively, outside Docker.
- Before analysis or execution, save and close every workbook in Excel.
- Grant macOS Automation permission only to the terminal/runtime that launches ExcelAgent.
- Keep one Excel job active at a time.

## Failure recovery

- `blocked_excel_busy`: save and close Excel workbooks, then retry the same job.
- Automation permission denied: enable the launching terminal under macOS Privacy & Security, then repeat preflight.
- Planner or schema failure: retain source and session audit data; no Excel execution occurs.
- Execution timeout or partial failure: retain the source, quarantine the working artifact, and start a retry from a fresh copy.
- Verification failure: inspect the report; the failed artifact is not offered as a completed download.

## Data and secrets

Session metadata lives in SQLite and workbook artifacts live under the configured local data directory. Both persist until the user deletes the session. `OPENAI_API_KEY` and workbook contents must be redacted from logs.

