# ExcelAgent MVP design

- Status: Approved in conversation; pending repository review
- Date: 2026-08-25
- Audience: implementers and reviewers

## Goal and success criteria

Build a single-user macOS web application that converts Vietnamese office-work requests into reviewed, typed operations executed through Microsoft Excel desktop.

The MVP succeeds when it can create and edit a task/project tracker from chat plus XLSX or CSV; produce formulas, professional formatting, validation, conditional formatting, KPI charts, and a dashboard; preserve the uploaded source and every unrelated workbook region; explain and require approval for each plan revision; and publish only an output that passes verification.

## Scope boundaries

The MVP supports macOS, Excel desktop, OpenAI, `.xlsx`, `.csv`, local session history, and a localhost web UI. It does not support Windows, Docker runtime, accounts, collaborative access, PDF/DOCX/web inputs, arbitrary Python/VBA, UDFs, macro injection, or external data connections.

Macro-enabled or externally connected workbooks may be inventoried for read-only analysis, but the executor rejects an operation that would introduce or depend on those features.

## Architecture

React and TypeScript provide chat, upload, plan preview, approval, progress, history, and download flows. FastAPI exposes localhost HTTP and SSE. Application services orchestrate a typed domain core, OpenAI planner, SQLite/session artifact store, serial Excel worker, and verifier.

OpenAI uses the Responses API with strict JSON Schema. It produces a `WorkbookPlan`; it never receives an execution tool capable of arbitrary code. Pydantic validation and safety rules run before a plan can enter `awaiting_approval`. The executor accepts only the approved plan revision and operates on a fresh working copy.

The runtime uses Python 3.12 managed by `uv`, React/Vite, SQLite, and xlwings. It binds to `127.0.0.1` and runs natively on macOS.

## Domain contracts

### WorkbookSnapshot

`WorkbookSnapshot` contains `source_artifact_id`, `source_hash`, sheet names and visibility, used ranges, required values and formulas, tables, names, validations, style summaries, charts, pivots, macro/external-link inventory, non-empty cell count, and analyzer warnings.

Snapshot construction stops with a user-facing error when the artifact exceeds 25 MB or the workbook exceeds 200,000 non-empty cells.

### WorkbookPlan

`WorkbookPlan` contains `plan_id`, `session_id`, `revision`, `goal`, `assumptions`, `warnings`, `source_hash`, `impacted_ranges`, ordered `operations`, estimated risk, and planner usage. Every revision replaces the approval eligibility of the previous revision.

`WorkbookOperation` is a discriminated union with these MVP operation kinds:

- create or rename sheet;
- write values, table, or formula;
- format a range;
- add data validation or conditional formatting;
- freeze panes or autofit;
- create a chart;
- clear content or delete a sheet with an explicit destructive risk flag.

Formula operations reject external workbook references and DDE. CSV cells beginning with `=`, `+`, `-`, or `@` are text unless a typed formula operation targets the cell.

### Approval and jobs

Approval requires matching `plan_id`, `revision`, and `source_hash`. The service rechecks the source hash before execution. Job states are `uploaded`, `analyzed`, `planned`, `awaiting_approval`, `executing`, `verifying`, `completed`, `failed`, and `blocked_excel_busy`.

One Excel job may run at a time. Analysis and execution stop in `blocked_excel_busy` when Excel has another workbook open. An Excel job times out after five minutes.

### VerificationReport

`VerificationReport` records source and output hashes, individual checks, warnings, failures, impacted-range evidence, formula-error comparison, expected sheet/table/chart/validation presence, and artifact IDs. Completion requires the output to reopen in Excel, recalculate, preserve out-of-scope fingerprints, and introduce no formula error. Failed working copies are quarantined and are not exposed as completed downloads.

## Data flow

For creation, the service normalizes chat and uploaded tabular inputs, obtains and validates a plan, shows its revision for approval, executes against a new workbook, recalculates, verifies, and publishes a new output artifact.

For editing, the service stores an immutable source and hash, analyzes a fresh copy, plans against the snapshot, validates approval and source preconditions, executes on another fresh copy, verifies preservation, and publishes a differently identified output. Refinement messages create a new plan revision.

SQLite stores sessions, messages, plan revisions, usage, audit events, artifact metadata, and reports. Files live in a dedicated local artifact directory. A session and all associated files persist until explicit deletion.

## HTTP interface

- `POST /api/sessions` creates a session.
- `GET /api/sessions` lists local history.
- `DELETE /api/sessions/{session_id}` deletes session metadata and artifacts atomically.
- `POST /api/sessions/{session_id}/artifacts` uploads validated XLSX or CSV content.
- `POST /api/sessions/{session_id}/messages` adds or refines an instruction.
- `GET /api/sessions/{session_id}/plans/current` returns the eligible plan revision.
- `POST /api/plans/{plan_id}/approve` accepts revision and source hash.
- `POST /api/plans/{plan_id}/reject` rejects the current revision.
- `POST /api/jobs/{job_id}/retry` retries a recoverable blocked or failed job from a fresh copy.
- `GET /api/sessions/{session_id}/events` streams job state over SSE.
- `GET /api/artifacts/{artifact_id}/download` returns an authorized local artifact; result artifacts require passing verification.

Client requests use opaque IDs and never supply arbitrary filesystem paths. Authentication is absent in v1 because the server binds only to localhost.

## Resource, privacy, and failure policy

The default OpenAI model is `gpt-5` and may be overridden with `OPENAI_MODEL`. A session is limited to 100,000 combined input/output tokens; a planning response is limited to 8,000 output tokens; transient or schema failure receives one retry. Usage is visible in the UI. Reaching the cap stops planning with a user-facing explanation.

`OPENAI_API_KEY` comes from environment configuration or a future keychain adapter. Secrets and workbook content are redacted from logs. Planner failure never starts Excel. Execution failure preserves the source, quarantines the working copy, and records an audit event. Verification failure withholds the result.

## Reference workflow

The first golden workflow creates a task/project tracker with `Tasks`, `Lists`, and `Dashboard` sheets. It supports task, owner, deadline, status, priority, percent progress, validation lists, overdue/progress formatting, KPI totals, and progress charts. It is the initial quality reference, not the only permitted workbook schema.

## Testing and delivery

CI runs unit, contract, integration, frontend, lint, typecheck, and build checks without live OpenAI or Excel. OpenAI and Excel adapters have deterministic fakes. Relevant feature PRs also run local Excel E2E on the target Mac and record evidence in the PR. The complete acceptance suite is defined in `docs/testing.md`.

Every roadmap item after bootstrap uses its own branch and pull request. Feature plans live under `docs/superpowers/plans/`, specify exact files and interfaces, follow RED/GREEN TDD, and end with focused English Conventional Commits. Direct pushes to `main` are prohibited after the empty bootstrap commit.

