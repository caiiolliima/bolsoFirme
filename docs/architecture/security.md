# Security Architecture

- **Date:** 2026-08-13
- **Status:** Target design. Controls land phase by phase.

## 1. Purpose and posture

Bolso Firme handles a single user's complete financial picture: what they earn, what they spend, where they spend it, and what they are saving toward. That data is sensitive by default, so security here is shift-left: every control described below is designed together with the module that needs it, written into the module's acceptance criteria, and reviewed in the same pull request as the feature — never bolted on by a later audit pass. A module is not done when it works; it is done when it works, validates its inputs, refuses what it does not recognise, and leaves an audit trail. This document describes the **target** design for the whole system. Nothing here is claimed as implemented today: authentication and secret handling land in Phase 0, encryption and audit logging harden alongside the features that produce sensitive rows, and tenant isolation becomes a first-class acceptance criterion in Phase 5. See [the roadmap](../product/roadmap.md) for the phase in which each control is expected to arrive, and [the architecture overview](overview.md) for the layer vocabulary (`domain`, `application`, `infrastructure`, `interface`) used throughout.

## 2. Controls

| Domain | Implementation |
|---|---|
| Authentication | JWT + refresh token (`HttpOnly`, `SameSite=Strict`, automatic rotation) |
| Authorization | RBAC via decorators (`@Roles('admin')`), per-route guards |
| Financial data | Encryption at rest (AES-256), masking in logs, guaranteed LGPD deletion |
| Secrets | `.env` locally → AWS Secrets Manager or Vault in production. Zero hardcoding |
| Validation | Zod + NestJS `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true` |
| Threats | STRIDE threat modeling per module. Rate limiting, restricted CORS, input sanitization |
| Audit | Structured JSON logs, `x-request-id` per flow, immutable `audit_log` table |

Each row is expanded in the sections that follow, except authorization and validation, which are short enough to state fully here. Authorization is enforced at the `interface` layer by NestJS guards reading role metadata from a `@Roles('admin')` decorator, so a route without an explicit decision is denied rather than open; ownership checks live one layer deeper, in the `application` use case, because "is this row yours" is a domain question and not a routing one. Validation runs through the shared Zod schemas defined once in the shared package, wired into a NestJS `ValidationPipe` configured with `whitelist: true` and `forbidNonWhitelisted: true`: unknown properties are stripped, and a payload that carried them is then rejected outright rather than silently accepted in a reduced form. That combination is deliberate — stripping alone would let a client believe a field was honoured when it was discarded.

## 3. Authentication flow

Authentication issues two tokens with deliberately different lifetimes and storage. The **access token** is a short-lived JWT carrying the user identifier and roles. It is held in memory by the frontend and never written to `localStorage`, `sessionStorage`, or a readable cookie, so a successful cross-site scripting payload has a very small window and no persistent artifact to steal. The **refresh token** is delivered in a cookie marked `HttpOnly`, `SameSite=Strict`, and `Secure`, which puts it out of reach of page JavaScript and out of scope for cross-site requests.

Refresh is a rotation, not a renewal. Each call to the refresh endpoint issues a brand new refresh token and invalidates the one that was presented, so a given refresh token is valid exactly once. The server tracks tokens as a **session family**: every token issued from the same original login shares a family identifier, and each rotation records its predecessor.

That bookkeeping exists for one reason. If an invalidated refresh token is ever presented again, there are only two explanations — a client that replayed a stale request, or an attacker using a token that was captured before the legitimate client rotated it. The system cannot distinguish them, so it assumes the worse case: **reuse of an invalidated refresh token is treated as compromise, and the entire session family is revoked immediately.** The legitimate user is forced to authenticate again, which is a small cost, and the attacker's stolen token stops working at the same moment, which is the point. The revocation is written to the `audit_log` table so the event is visible after the fact.

Logout revokes the current family server-side rather than only clearing the cookie, because a cookie cleared in one browser says nothing about a token copied elsewhere.

## 4. Data protection

Sensitive data in this product is not an abstract category, so it is enumerated rather than gestured at:

- **Transaction amounts and descriptions** — together they reveal income, habits, health, and location.
- **Account identifiers** — bank, agency, and account numbers captured during statement import.
- **Imported statement files** — raw OFX and CSV uploads, which contain more fields than the parser keeps.
- **Goal and portfolio values** — net worth is at least as sensitive as any single transaction.
- **Authentication material** — password hashes and refresh-token records.

These are encrypted **at rest with AES-256**, covering the database volume and any object storage holding uploaded statement files. Passwords are never encrypted, only hashed with a memory-hard algorithm, because encryption implies a key that can reverse the operation and no such reversal should be possible. Transport is TLS end to end; the API refuses plaintext connections.

**Masking in logs is a hard rule.** Structured logs may carry a transaction identifier but never its description; they may record that a statement was imported and how many rows it produced, but never a row's contents. Account numbers appear masked to their last digits when they appear at all. The masking is applied by the logger's serialiser in the `infrastructure` layer rather than by each call site, because a rule that depends on every developer remembering it is not a rule. Error paths get the same treatment as success paths — an exception message that echoes an unparsed request body is the most common way sensitive data reaches a log file, so request payloads are never attached verbatim to error reports.

**LGPD deletion is a guarantee, not a best effort.** A deletion request removes the user's personal data — profile, transactions, budgets, goals, portfolio, imported files, and authentication material — across primary storage and backups within the retention window published to the user. The immutable `audit_log` table is the single deliberate exception, and it is narrow: what remains is a non-identifying record that an action of a given type occurred at a given time against a now-anonymised subject identifier. It retains no name, no email, no amount, and no description. This keeps the audit trail meaningful for security investigation and for proving that the deletion itself was carried out, while leaving nothing behind that reconstructs the person. The tension between an append-only audit log and a right to erasure is real, and this is the resolution the project commits to.

## 5. Threat modeling

Every module is threat-modeled with **STRIDE** — Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege — and the modeling happens **while the module is being designed, not after it ships**. The output is a short list of concrete threats and the specific control that addresses each, recorded with the module's design notes and revisited when the module changes shape. Threat modeling after release produces a backlog; threat modeling during design produces acceptance criteria.

The cross-cutting mitigations that fall out of this exercise for nearly every module are rate limiting on authentication and import endpoints, a CORS policy restricted to known origins rather than a wildcard, and input sanitization at the `interface` boundary before any value reaches the `application` layer.

### Worked example: statement import

The statement-import flow is the clearest case, so it is written out in full.

The flow accepts an OFX or CSV file uploaded by the user, parses it, and turns it into transaction rows. Under STRIDE, the dominant category is **tampering**: the file is attacker-controlled input that arrives looking like a trusted bank document. A malicious or simply malformed statement can attempt formula injection through cells that a spreadsheet would later evaluate, XML external entity expansion through OFX's SGML/XML lineage, decompression and entity-expansion bombs aimed at exhausting memory, wildly out-of-range or non-numeric amounts intended to corrupt aggregate calculations, and field values crafted to be interpreted as markup or SQL further downstream.

Spoofing appears as a file claiming to originate from an institution it does not; the system's answer is that it never trusts provenance metadata for anything that matters. Denial of service appears as a very large upload; the answer is an enforced size limit, a row-count ceiling, and a parse timeout. Information disclosure appears as parser errors quoting file contents back to the user or into logs; the answer is the masking rule from the previous section.

The core mitigation is structural and applies to all of it: **the file is parsed into a Zod-validated shape before anything is persisted, and file content is never evaluated.** Concretely — the parser runs with external entity resolution disabled and with size, row-count, and time limits enforced before parsing begins; the extracted rows are validated against the shared Zod transaction schema, so amounts must be numbers in a plausible range, dates must be real dates, and unknown columns are dropped rather than carried along; anything failing validation is rejected as a whole file with a generic error rather than partially imported; every persisted value is a typed value produced by the schema, never a raw string copied from the source; and no field is ever passed to an evaluator, a template renderer, or a string-concatenated query. Text extracted from a statement is treated exactly like text typed by an anonymous stranger, because that is what it is. The same rule extends to the LLM boundary: a description string sent for auto-categorization is data, and the response comes back through its own Zod schema before it is allowed to influence a row.

## 6. Auditability

All application logs are **structured JSON** — one object per event, with stable field names — so they can be queried and alerted on rather than read. Human-readable formatting is a local development convenience only.

Every request is assigned an **`x-request-id`** at the edge, or adopts the one supplied by the caller when present, and that identifier is propagated through the entire flow: the controller, the use case, repository calls, background jobs spawned by the request, and outbound calls including LLM invocations, which log it alongside `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, and `validation_status`. One identifier therefore reconstructs a complete causal chain, from the click through the fallback that ran when a model call failed. Without this, correlating a user-reported problem with the log line that explains it is guesswork.

Security-relevant events are additionally written to an **immutable `audit_log` table**. The table is append-only by design and by permission: the application's database role holds `INSERT` and `SELECT` on it and no `UPDATE` or `DELETE`, so an application-level bug or a compromised application credential cannot rewrite history. Corrections are new rows, never edits. Each entry records the actor, the action, the affected resource type and identifier, the timestamp, the source address, and the `x-request-id` that ties it back to the full log stream — and, per the masking rule, never the sensitive values themselves. Logins, failed authentication attempts, refresh-token reuse detections and the family revocations they trigger, role and permission changes, data exports, and deletion requests all land here. Phase 4's payment flows and Phase 5's shared-budget permission changes both depend on this table being trustworthy.

## 7. Multi-tenant isolation

Through Phase 4 the model is single-tenant in the simplest possible sense: every row belongs to exactly one user, and a query that forgets to filter by owner returns nothing useful because there is nothing else in scope for that user's session. **Phase 5 changes that.** Groups, invitations, and shared budgets introduce records that legitimately belong to more than one person, with different roles over the same data, and at that point "filter by owner" stops being a formality and becomes the load-bearing security control of the entire product.

The design commitment made now, ahead of that work: every query that touches shared data is scoped by owner or group membership at the repository level, not at the controller and not by convention. Scoping belongs in the `infrastructure` implementation of each repository interface so that no `application` use case can accidentally issue an unscoped read, and membership is resolved from the authenticated session rather than from any client-supplied group identifier — a request that names a group it does not belong to is a permission error, not a lookup. Row-level security in PostgreSQL is the intended second layer of defence, so that isolation survives a mistake in application code.

**Cross-tenant leakage is the primary acceptance criterion for Phase 5.** No amount of working functionality compensates for one user seeing another's transaction, so the phase is not done until an automated test suite proves, for every shared endpoint, that a member of group A receives a not-found or forbidden response for group B's resources — including on list endpoints, on aggregate and reporting queries where a stray sum is the easiest leak to miss, and on error messages that could confirm a resource exists. The phase's deliverables and acceptance criteria are listed in [the roadmap](../product/roadmap.md).
