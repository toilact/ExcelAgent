# ADR-0001: Declarative Excel execution

- Status: Accepted
- Date: 2026-08-25

## Decision

OpenAI produces a strict, typed `WorkbookPlan`. A deterministic validator and whitelisted Excel executor apply the approved plan. The model cannot emit executable Python or VBA.

## Consequences

- Plans are previewable, revisioned, auditable, and testable without Excel.
- New Excel capabilities require an explicit operation type, validator rule, executor implementation, and tests.
- Free-form workbook automation is intentionally narrower than code generation.
- The boundary reduces arbitrary-code and unreviewed-mutation risk.

## Alternatives rejected

- Model-generated Python: flexible but difficult to sandbox, audit, and constrain to approved ranges.
- VBA or Office Add-in core: higher Office coupling and a second application stack before the local web MVP is proven.
