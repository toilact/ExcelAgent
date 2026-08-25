# ExcelAgent agent guide

## Start here

1. Read the [MVP design](docs/superpowers/specs/2026-08-25-excel-agent-mvp-design.md).
2. Find the current session in [the roadmap](docs/roadmap.md); work on one session only.
3. Read that feature's plan under `docs/superpowers/plans/` before changing code.
4. Use the commands and evidence rules in [the testing guide](docs/testing.md).

## Delivery gate

- Branch from updated `main` using `docs/`, `chore/`, or `feat/` plus the session slug.
- Preserve the declarative boundary: the model produces typed plans; only the validated Excel adapter mutates a working copy.
- Keep the uploaded source artifact immutable and keep the app bound to `127.0.0.1`.
- Follow TDD for behavior changes. Commit focused changes with short English Conventional Commit messages.
- Before opening a PR, run the full automated gate and any Excel E2E scenario named by the feature plan.
- Put verification evidence, risk, and rollback notes in the PR. One session produces one PR.

## Read on demand

- **Architecture or interface change:** read [architecture.md](docs/architecture.md) and the ADRs under `docs/adr/`.
- **Excel automation, local setup, or permission failure:** read [runbook.md](docs/runbook.md).
- **Test selection, CI, or completion claim:** read [testing.md](docs/testing.md).
- **Scope or sequencing question:** read [roadmap.md](docs/roadmap.md); changing an approved decision requires user agreement first.

