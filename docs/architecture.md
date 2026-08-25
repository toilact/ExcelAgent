# Architecture map

The [MVP design](superpowers/specs/2026-08-25-excel-agent-mvp-design.md) is authoritative for requirements and contracts. This document is the quick map used to locate responsibilities.

## Runtime boundaries

```text
React UI
  -> FastAPI session API + SSE
      -> application state machine
          -> OpenAI planner -> typed WorkbookPlan
          -> safety validator
          -> serial Excel worker -> xlwings -> Excel for Mac
          -> verifier
      -> SQLite metadata + local artifact store
```

- `domain`: dependency-free Pydantic contracts, operation validation, and job transitions.
- `planning`: OpenAI adapter, prompt construction, plan revisions, and token budget.
- `sessions`: session metadata, messages, artifacts, retention, and audit trail.
- `workbooks`: preflight, analyzer, Excel executor, fingerprints, and verification.
- `api`: localhost HTTP/SSE translation; it contains no workbook business rules.
- Frontend feature folders own chat, plan approval, workbook flows, and session history.

## Invariants

1. The language model can propose only typed operations; it cannot execute code.
2. Approval binds `plan_id`, `revision`, and `source_hash`.
3. Execution mutates a working copy and never the uploaded source.
4. Only a verified output is downloadable as a result.
5. Excel work is serialized and stops while another workbook is open.

See [ADR-0001](adr/0001-declarative-excel-execution.md) and [ADR-0002](adr/0002-native-macos-runtime.md) for the reasons behind these boundaries.

