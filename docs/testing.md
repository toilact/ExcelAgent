# Testing and evidence

The feature plan selects tests from this strategy and records exact commands. A completion claim requires a fresh full run against the current tree.

## Test layers

- **Unit:** domain schemas, validators, state transitions, formula/path safety, budget, and retention.
- **Contract:** mocked OpenAI Responses payloads and a fake Excel adapter. CI never calls OpenAI or Excel.
- **Integration:** API, SQLite, artifact filesystem, and application service boundaries.
- **Local Excel E2E:** Microsoft Excel for Mac performs real execution, recalculation, save, reopen, and verification.
- **Frontend:** Vitest component/flow tests, TypeScript checks, lint, and production build.

## Required acceptance scenarios

1. Create a task tracker from Vietnamese instructions and CSV.
2. Change task status or deadline while preserving unrelated sheets, formulas, and styles.
3. Add a dashboard and chart to an existing workbook.
4. Reject approval with a stale revision or source hash.
5. Reject oversized files, arbitrary paths, external formulas, and unsafe CSV content.
6. Block safely while Excel has another workbook open.
7. Preserve the source hash after successful and failed execution.
8. Quarantine output with a new formula error or out-of-scope fingerprint change.
9. Ensure planner timeout/schema failure never calls the executor.
10. Delete session metadata and every associated artifact together.

## PR evidence

Every PR records:

- exact commands and exit status for lint, typecheck, tests, and build;
- local Excel E2E command and result when the change reaches Excel behavior;
- skipped gates with a concrete reason;
- risk and rollback notes.

The milestone exit gate is the complete automated suite plus the complete local Excel regression suite.

