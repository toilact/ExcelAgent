# ADR-0003: Local HTTP trust boundary

- Status: Accepted
- Date: 2026-08-25

## Decision

Treat loopback binding as network exposure control, not authorization. Accept only the configured API Host and UI Origin, bootstrap an authenticated local session through a one-time 256-bit launch token, and authorize mutations, SSE, and downloads with an `HttpOnly; SameSite=Strict` cookie.

## Consequences

- DNS rebinding and untrusted browser origins cannot invoke the local API through ambient network access.
- The launcher and frontend must complete the fragment-to-cookie exchange and remove the fragment before normal API use.
- Integration and frontend tests must cover Host, Origin, token invalidation, cookie flags, protected endpoints, and secret redaction.
- User accounts remain unnecessary for the single-user MVP.

## Alternatives rejected

- Loopback binding alone: local browser-origin and DNS-rebinding threats remain.
- Persistent API keys in browser storage: secrets survive longer than the app process and are exposed to frontend script access.
- Full account authentication: adds identity and credential lifecycle work without improving the single-user local workflow.
