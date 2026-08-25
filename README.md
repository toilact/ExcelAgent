# ExcelAgent

ExcelAgent is a local-first macOS web application that turns Vietnamese office-work requests into reviewed, typed workbook operations. OpenAI plans the work; a deterministic Python adapter executes approved operations through Microsoft Excel without overwriting the uploaded source.

The repository is currently at the documentation gate. Implementation begins only after the MVP design is reviewed and merged.

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
