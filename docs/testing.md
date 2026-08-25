# Testing and evidence

The feature plan selects tests from this strategy and records exact commands. A completion claim requires a fresh full run against the current tree.

## Session 2 command surface

`./scripts/check` is the canonical automated PR gate and is the command run by CI after locked backend and frontend installs. Run it from any directory:

```bash
./scripts/check
```

The Session 2 local evidence also requires the development smoke test:

```bash
bash scripts/tests/dev-smoke.sh
```

The smoke test starts long-lived development services, validates the API and UI, and cleans them up. It is intentionally not run in CI.

## Test layers

- **Unit:** domain schemas, validators, state transitions, formula/path safety, budget, and retention.
- **Contract:** mocked OpenAI Responses payloads and a fake Excel adapter. CI never calls OpenAI or Excel.
- **Integration:** API, SQLite, artifact filesystem, and application service boundaries.
- **Local Excel E2E:** Microsoft Excel for Mac performs real execution, recalculation, save, reopen, and verification.
- **Frontend:** Vitest component/flow tests, TypeScript checks, lint, and production build.

## Required acceptance scenarios

1. Create a task tracker from Vietnamese instructions and CSV; assert formulas, number/date formats, validation lists, conditional formatting, KPI totals, charts, and the `Tasks`, `Lists`, and `Dashboard` sheets.
2. Change task status or deadline while preserving unrelated sheets, formulas, styles, validations, and charts.
3. Add a dashboard and chart to an existing workbook without changing unrelated fingerprints.
4. Explain assumptions, warnings, impacted ranges, and risk for every plan revision; reject approval with a stale revision or source hash.
5. Accept inputs immediately below and exactly at 25 MB and 200,000 non-empty cells; reject inputs immediately above either boundary.
6. Reject an XLSX that exceeds the entry, expanded-byte, single-entry, compression-ratio, sheet, cell-length, parse-time, or analyzer-memory limit before Excel or OpenAI is called.
7. Inventory macros and external connections during read-only analysis without mutation; reject operations that introduce or depend on them. Also reject arbitrary paths, external formulas, DDE, and CSV cells that would otherwise trigger formula execution.
8. Reject non-loopback Host values, untrusted Origin/Referer values, missing/invalid/reused launch tokens, and permissive CORS. Verify fragment removal, one-time token invalidation, exact cookie flags, cookie enforcement for mutation/SSE/download, and absence of tokens/cookies from URLs after bootstrap, SQLite, and logs.
9. Block safely while Excel has another workbook open and allow retry after it closes.
10. Stop an Excel job at the five-minute timeout and restart only from a fresh working copy.
11. Preserve the source hash after successful, failed, and timed-out execution.
12. Quarantine output with a new formula error or out-of-scope fingerprint change.
13. Ensure planner timeout or schema failure receives at most one retry and never calls the executor.
14. Enforce 100,000 combined tokens per session and 8,000 output tokens per planning response while reporting usage.
15. Simulate a crash before and after deletion quarantine; startup recovery must complete the tombstoned deletion without visible sessions, metadata leaks, or orphan artifacts.

## PR evidence

Every PR records:

- exact commands and exit status for lint, typecheck, tests, and build;
- local Excel E2E command and result when the change reaches Excel behavior;
- skipped gates with a concrete reason;
- risk and rollback notes.

At each milestone exit, run the complete automated suite plus every local Excel regression scenario implemented so far. The Excel portion is not applicable until Milestone 2 introduces the real executor.

## Invariant ownership

| Invariant | Owning session | Required layer |
| --- | --- | --- |
| Typed operations and formula/DDE rejection | 3 | Unit |
| Upload, archive, path, size, cell, time, and memory limits | 4 | Unit + integration |
| Tombstoned deletion and crash recovery | 4 | Integration |
| Excel busy detection and immutable snapshot | 5 | Contract + local Excel E2E |
| Token limits, retry, and log redaction | 6 | Unit + contract |
| Revision/source-hash approval | 7 | Unit + integration |
| Five-minute timeout and fresh-copy recovery | 8 | Contract + local Excel E2E |
| Local Host/Origin/token trust boundary | 2 | Integration + frontend |
| Output fingerprints and formula verification | 11 | Contract + local Excel E2E |
| Adversarial cross-boundary regression | 18 | Full automated + local Excel E2E |
