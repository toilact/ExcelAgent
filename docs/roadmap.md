# Session roadmap

Each numbered item is one development session, one branch, and one pull request. A later session starts only after its dependency is reviewed and merged.

## Bootstrap

0. `chore: initialize repository` — empty base commit on `main`; this is the only direct push to `main`.

## Milestone 0 — Documentation and foundation

1. `docs/agent-workflow` — design spec, agent entrypoint, architecture, testing, runbook, ADRs, and PR template.
2. `chore/project-foundation` — FastAPI/React health slice, `uv` and npm configuration, scripts, and CI.

## Milestone 1 — Analyze and plan without mutation

3. `feat/domain-contracts` — Pydantic contracts, operation union, validator, and state machine.
4. `feat/session-artifacts` — SQLite sessions, immutable artifact store, upload limits, and deletion.
5. `feat/excel-preflight-analyzer` — Automation permission, Excel-busy detection, snapshot, and fingerprint.
6. `feat/openai-planner` — strict structured output, prompt contract, token budget, and mocked contracts.
7. `feat/plan-approval` — preview, revision, approval/rejection, stale-plan guard, and SSE states.

## Milestone 2 — Create workbooks

8. `feat/excel-executor-core` — serial worker, sheets, values, tables, formulas, and artifact lifecycle.
9. `feat/excel-formatting` — styles, formats, autofit, freeze panes, validation, and conditional formatting.
10. `feat/excel-charts` — chart operations and dashboard primitives.
11. `feat/output-verification` — reopen/recalculate, invariant checks, reports, and quarantine.
12. `feat/task-tracker-create` — `Tasks`, `Lists`, and `Dashboard` reference workflow with golden E2E.
13. `feat/create-workbook-ui` — chat through approved, verified download.

## Milestone 3 — Preserve and edit workbooks

14. `feat/workbook-editing` — edit/delete operations, risk flags, range fingerprints, and preservation tests.
15. `feat/edit-plan-revisions` — chat refinement, source-hash recheck, and stale-approval UX.
16. `feat/edit-workbook-ui` — before/after summary and full edit workflow.

## Milestone 4 — Daily use and hardening

17. `feat/session-history` — history, usage, artifact/report retrieval, and deletion flows.
18. `feat/security-reliability` — formula/path defenses, redacted logs, timeout/retry, recovery, and boundary suite.
19. `chore/mvp-release` — full regression, setup and troubleshooting documentation, and release checklist.

## Session entry and exit

From Session 2 onward, add the feature plan at `docs/superpowers/plans/YYYY-MM-DD-<slug>.md` as the first branch commit. The plan must name exact interfaces, tests, RED/GREEN commands, and task-level commits. A session exits only after automated checks, required local Excel E2E, review, push, and PR creation.

