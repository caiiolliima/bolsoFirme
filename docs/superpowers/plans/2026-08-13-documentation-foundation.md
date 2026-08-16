# Documentation Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Portuguese scope document and the retired Qwen agent context into a complete English documentation set — operational context, product vision, architecture, ADRs, and engineering guardrails — that reads as production-grade to anyone opening the public repository.

**Architecture:** Documentation only; no product code ships in this plan. Content flows from the leaves inward: ADRs first (nothing links *out* of them), then architecture and product documents that cite those ADRs, then `CLAUDE.md` and `README.md`, which link to everything. A shell script (`scripts/check-docs.sh`) provides the red/green cycle in place of unit tests — it validates link resolution, placeholder discipline, and English-only prose.

**Tech Stack:** Markdown, Bash, git. The documented system targets Next.js 14+, NestJS 10+, PostgreSQL 16, Prisma, Zod, Docker Compose, and Turborepo, but none of it is installed here.

**Spec:** `docs/superpowers/specs/2026-08-13-documentation-foundation-design.md`

## Global Constraints

- **Language:** every file created by this plan is written in English. No Portuguese prose in any committed file.
- **Date used in all document front matter and ADRs:** `2026-08-13`.
- **ADR author / decider:** `Caio Lima`.
- **ADR status:** every ADR is `Accepted` *except* ADR-0005, which is `Proposed` and carries an `Open Questions` section. This is deliberate and must not be "fixed".
- **Only two placeholders are permitted** in the entire documentation set, and both must contain the exact string `pending Phase 0`: the commands section of `CLAUDE.md` and the local-setup section of `README.md`. The check script treats any other `TBD`/`TODO`/`FIXME` as a failure.
- **Verbatim technical values** — copy these exactly wherever they appear:
  - Next.js 14+ (App Router), NestJS 10+, PostgreSQL 16, Prisma ORM, Zod, Docker Compose, Turborepo
  - Test coverage floor: `≥ 70%` (Phase 2 raises its own bar to `≥ 80%`)
  - CI pipeline order: `lint → test:coverage(≥70%) → build → scan → deploy`
  - Pull-request gate order: `test → lint → schema validation → manual code review`
  - LLM temperature: `≤ 0.3` for financial analysis, `≤ 0.2` for goal projection, never `> 0.5` on sensitive data
  - LLM observability fields: `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status`
  - Prompt registry path: `/packages/prompts/`
  - Monolith split criteria: latency above 2s, blocked deploys, or a genuine need for independent scaling
  - Latency targets: p95 < 1s (Phase 1), < 500ms (Phase 6)
  - Auth: JWT + refresh token, `HttpOnly`, `SameSite=Strict`, automatic rotation
  - Validation pipe: `whitelist: true`, `forbidNonWhitelisted: true`
- **Commit style:** Conventional Commits, `docs:` prefix, English message bodies.

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/check-docs.sh` | Validates the documentation set: link resolution, placeholder discipline, English-only prose |
| `docs/adr/template.md` | The ADR format every decision record follows |
| `docs/adr/0001-modular-monolith-over-microservices.md` | Why one deployable, and the criteria for splitting it |
| `docs/adr/0002-nextjs-nestjs-typescript-stack.md` | Frontend, backend, and language selection |
| `docs/adr/0003-postgresql-prisma-orm.md` | Persistence engine and data-access layer |
| `docs/adr/0004-zod-shared-validation-contract.md` | One validation contract across frontend and backend |
| `docs/adr/0005-turborepo-monorepo-tooling.md` | Monorepo tooling — **Proposed, still open** |
| `docs/adr/0006-llm-guardrails-deterministic-fallback.md` | How LLM output is constrained in a financial domain |
| `docs/architecture/overview.md` | Stack, modular monolith, DDD layers, monorepo layout |
| `docs/architecture/security.md` | AuthN/AuthZ, encryption, secrets, threat model, audit |
| `docs/architecture/ai-integration.md` | LLM features in the product and LLM discipline in development |
| `docs/product/vision.md` | Problem, solution, differentiator, engineering objective |
| `docs/product/roadmap.md` | Phases 0–7+ with deliverables and acceptance criteria |
| `docs/engineering/guardrails.md` | Anti-vibe-coding contract, CI/CD gates, definition of done, metrics |
| `CLAUDE.md` | Operational context for development sessions |
| `README.md` | Repository front door |

Deleted at the end: `docs/bolso-firme-escopo.md` (tracked), `.qwen/` and `test.ts` (untracked).

---

### Task 1: Documentation check script

The rest of the plan has no unit tests, so this script *is* the test harness. It must exist and demonstrably detect a real problem before any document is written.

**Files:**
- Create: `scripts/check-docs.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: executable `scripts/check-docs.sh`, run as `./scripts/check-docs.sh` from anywhere in the repository. Exit code `0` means clean; `1` means findings, printed to stdout. Every later task runs this command.

- [ ] **Step 1: Write the script**

Create `scripts/check-docs.sh`:

```bash
#!/usr/bin/env bash
# check-docs.sh — validates the public documentation set.
#
#   1. every relative markdown link resolves to a file that exists
#   2. no stray TBD/TODO/FIXME markers outside the allow-list
#   3. no Portuguese prose leaked into the English documentation
#
# Exit 0 = clean, 1 = findings printed to stdout.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

status=0

# Public documentation only. docs/superpowers/ holds process artifacts (specs,
# plans) rather than product documentation, and is intentionally exempt.
#
# --others --exclude-standard includes files that exist but are not yet staged,
# which matters because this script runs before each commit: without it, a
# freshly written document would be skipped and pass by not being looked at.
mapfile -t files < <(
  git ls-files --cached --others --exclude-standard '*.md' \
    | grep -v '^docs/superpowers/' \
    | sort -u
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "check-docs: no markdown files tracked yet"
  exit 0
fi

# --- 1. relative links resolve ---------------------------------------------
broken=""
for f in "${files[@]}"; do
  dir="$(dirname "$f")"
  targets="$(grep -oE '\]\([^)]+\)' "$f" \
    | sed -E 's/^\]\(//; s/\)$//' \
    | grep -vE '^(https?://|mailto:|#)' || true)"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    path="${target%%#*}"
    [ -z "$path" ] && continue
    if [ ! -e "$dir/$path" ]; then
      broken+="  $f -> $target"$'\n'
    fi
  done <<< "$targets"
done
if [ -n "$broken" ]; then
  echo "Broken relative links:"
  printf '%s' "$broken"
  status=1
fi

# --- 2. stray placeholders --------------------------------------------------
# The CLAUDE.md commands section and the README setup section are deliberately
# unfinished until Phase 0 lands; both label themselves "pending Phase 0".
placeholders="$(grep -nE '\b(TBD|TODO|FIXME)\b' "${files[@]}" \
  | grep -v 'pending Phase 0' || true)"
if [ -n "$placeholders" ]; then
  echo "Unlabeled placeholders:"
  echo "$placeholders" | sed 's/^/  /'
  status=1
fi

# --- 3. Portuguese leakage --------------------------------------------------
# The tilde and cedilla characters are effectively absent from English prose,
# which makes them a cheap, low-false-positive signal for untranslated text.
portuguese="$(grep -nE '[ãõç]' "${files[@]}" || true)"
if [ -n "$portuguese" ]; then
  echo "Portuguese text in English documentation:"
  echo "$portuguese" | sed 's/^/  /'
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "check-docs: clean"
fi
exit "$status"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x scripts/check-docs.sh`

- [ ] **Step 3: Run it to verify it detects a real problem**

Run: `./scripts/check-docs.sh; echo "exit=$?"`

Expected: exit `1`, with a `Portuguese text in English documentation:` block listing many lines from `docs/bolso-firme-escopo.md`. That file is the untranslated scope document and is deleted in Task 11.

This failure is the proof the check works. **From Task 2 through Task 10, the only acceptable findings are Portuguese hits in `docs/bolso-firme-escopo.md`.** Any broken link, any placeholder, or any Portuguese hit in a different file is a genuine failure that must be fixed before committing.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-docs.sh
git commit -m "docs: add documentation check script

Validates link resolution, placeholder discipline, and English-only prose
across the public documentation set."
```

---

### Task 2: ADR template and ADR-0001

**Files:**
- Create: `docs/adr/template.md`
- Create: `docs/adr/0001-modular-monolith-over-microservices.md`

**Interfaces:**
- Consumes: `scripts/check-docs.sh` from Task 1.
- Produces: the ADR section layout — `Status`, `Date`, `Deciders`, `Context`, `Decision`, `Consequences` (with `Positive` / `Negative` / `Neutral` subsections), `Alternatives Considered`, and an optional `Open Questions`. Tasks 3 and 4 reuse this layout exactly. Filenames follow `NNNN-kebab-case-title.md`.

- [ ] **Step 1: Write `docs/adr/template.md`**

```markdown
# ADR-NNNN: <Short title of the decision>

- **Status:** Proposed | Accepted | Superseded by ADR-XXXX | Deprecated
- **Date:** YYYY-MM-DD
- **Deciders:** <name>

## Context

The forces at play: the constraint, requirement, or problem that makes a
decision necessary. State facts, not the decision itself. A reader should be
able to disagree with the decision while still agreeing with this section.

## Decision

The choice, in one or two sentences, in active voice: "We will ...".

## Consequences

### Positive

What gets easier or cheaper.

### Negative

What gets harder or more expensive. An ADR with no negative consequences has
not been thought through.

### Neutral

Follow-on effects that are neither wins nor costs, but that a future reader
needs to know.

## Alternatives Considered

### <Alternative name>

What it is, and the specific reason it was not chosen. "It was worse" is not a
reason; name the trade-off.

## Open Questions

Anything still unresolved. Omit this section entirely when the decision is
settled.
```

- [ ] **Step 2: Write `docs/adr/0001-modular-monolith-over-microservices.md`**

Follow the template. Status `Accepted`, date `2026-08-13`, deciders `Caio Lima`. Content requirements:

- **Context:** solo developer; no production traffic and therefore no measured bottleneck; the domain (transactions, budgets, goals, portfolio) is highly cohesive and shares a single user's financial data; distributed transactions across a financial domain are expensive to get right.
- **Decision:** "We will build the backend as a modular monolith — one deployable NestJS application with strict internal module boundaries and DDD layering — and extract services only when measurements demand it."
- **Consequences → Positive:** one deployment target, local reproduction of the whole system with Docker Compose, refactoring across boundaries stays cheap while the domain model is still moving, ACID transactions remain available across the whole domain.
- **Consequences → Negative:** the whole application scales as a unit; a memory leak or hot loop in one module degrades all of them; module boundaries are enforced by discipline and review rather than by the network, so they can erode silently.
- **Consequences → Neutral:** DDD layering (`domain` / `application` / `infrastructure` / `interface`) is what makes later extraction feasible; it is a prerequisite of this decision, not a separate style preference.
- **Decision → include the explicit split criteria verbatim:** service extraction is reconsidered when p95 latency exceeds 2s, when deploys are blocked by unrelated modules, or when one module genuinely needs to scale independently.
- **Alternatives Considered → Microservices from day one:** rejected because the operational surface (service discovery, distributed tracing, per-service CI/CD, network-partition handling) costs more than a solo developer can carry, and it would be paid before a single metric justifies it.
- **Alternatives Considered → Serverless functions per endpoint:** rejected because cold starts conflict with the p95 < 1s target and because per-function state makes the shared domain model awkward to express.

- [ ] **Step 3: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1` with Portuguese findings **only** from `docs/bolso-firme-escopo.md`. No broken links, no placeholders, no Portuguese from the two new files.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/template.md docs/adr/0001-modular-monolith-over-microservices.md
git commit -m "docs: add ADR template and modular monolith decision"
```

---

### Task 3: ADR-0002 and ADR-0003

**Files:**
- Create: `docs/adr/0002-nextjs-nestjs-typescript-stack.md`
- Create: `docs/adr/0003-postgresql-prisma-orm.md`

**Interfaces:**
- Consumes: the ADR layout from `docs/adr/template.md` (Task 2).
- Produces: the ADR filenames that `docs/architecture/overview.md` (Task 5) and `CLAUDE.md` (Task 9) link to.

- [ ] **Step 1: Write `docs/adr/0002-nextjs-nestjs-typescript-stack.md`**

Status `Accepted`, date `2026-08-13`, deciders `Caio Lima`. Content requirements:

- **Context:** a solo developer benefits disproportionately from one language across the stack; the product needs server-rendered pages for first-paint on a data-heavy dashboard; the backend needs testable seams for DDD layering.
- **Decision:** "We will use TypeScript everywhere, Next.js 14+ with the App Router on the frontend, and NestJS 10+ on the backend."
- **Consequences → Positive:** types and Zod schemas cross the network boundary without translation; one toolchain for lint, test, and build; NestJS's native dependency injection makes the `application` layer testable without touching a database; the ecosystem is large enough that most problems are already answered.
- **Consequences → Negative:** NestJS's decorator-heavy style is opinionated and adds a learning curve; the App Router's server/client component split is a genuine source of subtle bugs; a single-language stack means a single-ecosystem risk.
- **Alternatives Considered → Remix or SvelteKit:** rejected because the dashboard leans on the React charting ecosystem (Recharts) and the React Native path in Phase 7+ makes React knowledge reusable.
- **Alternatives Considered → Express or Fastify:** rejected because the DI, guard, pipe, and module primitives that NestJS provides would have to be hand-rolled, and hand-rolled versions are where the DDD boundaries would erode first.
- **Alternatives Considered → A non-TypeScript backend (Go, Python):** rejected because it would break the shared Zod contract described in ADR-0004 and double the toolchain for one developer. Link to `0004-zod-shared-validation-contract.md`.

- [ ] **Step 2: Write `docs/adr/0003-postgresql-prisma-orm.md`**

Status `Accepted`, date `2026-08-13`, deciders `Caio Lima`. Content requirements:

- **Context:** the data is financial, so correctness under concurrent writes is non-negotiable; budgets and goals need aggregate queries over transactions; Phase 3+ anticipates embedding-based features; the developer is solo and cannot afford a hand-written data layer.
- **Decision:** "We will use PostgreSQL 16 as the database and Prisma as the ORM."
- **Consequences → Positive:** ACID transactions for multi-row financial writes; JSONB for parser output that has not earned a schema yet; the `pgvector` extension is available without a second datastore when AI features arrive; Prisma generates types that flow into the same TypeScript codebase as the Zod schemas; migrations are versioned and reviewable.
- **Consequences → Negative:** Prisma's query builder does not express every SQL construct, so complex reports may need raw SQL and lose type safety; Prisma adds a code-generation step to the build; the abstraction makes it easy to write N+1 queries without noticing.
- **Consequences → Neutral:** raw SQL escape hatches are acceptable when they are isolated inside the `infrastructure` layer and covered by tests.
- **Alternatives Considered → MongoDB:** rejected because multi-document transactions in a financial ledger are the default case, not the exception, and a document model would push that guarantee into application code.
- **Alternatives Considered → TypeORM:** rejected because its Active Record/Data Mapper duality and weaker type inference make repository interfaces harder to keep honest.
- **Alternatives Considered → Drizzle:** genuinely close; rejected on ecosystem maturity and migration tooling at decision time, with the note that this is the most likely ADR to be revisited.

- [ ] **Step 3: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. The cross-link from ADR-0002 to ADR-0004 will report as broken until Task 4 creates that file — **that is expected here**, and Task 4's check must show it resolved.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/0002-nextjs-nestjs-typescript-stack.md docs/adr/0003-postgresql-prisma-orm.md
git commit -m "docs: add stack and persistence ADRs"
```

---

### Task 4: ADR-0004, ADR-0005, and ADR-0006

**Files:**
- Create: `docs/adr/0004-zod-shared-validation-contract.md`
- Create: `docs/adr/0005-turborepo-monorepo-tooling.md`
- Create: `docs/adr/0006-llm-guardrails-deterministic-fallback.md`

**Interfaces:**
- Consumes: the ADR layout from `docs/adr/template.md`; resolves the forward link left by ADR-0002.
- Produces: `0006-llm-guardrails-deterministic-fallback.md`, which `docs/architecture/ai-integration.md` (Task 7) and `docs/engineering/guardrails.md` (Task 8) both cite.

- [ ] **Step 1: Write `docs/adr/0004-zod-shared-validation-contract.md`**

Status `Accepted`, date `2026-08-13`, deciders `Caio Lima`. Content requirements:

- **Context:** the same shapes (a transaction, a budget, an imported CSV row, an LLM response) are validated on the client, on the server, and at the LLM boundary; three hand-written validators for one shape is three chances to disagree.
- **Decision:** "We will define every cross-boundary shape once as a Zod schema in the shared package, and derive TypeScript types from those schemas rather than declaring types separately."
- **Consequences → Positive:** one source of truth for shape and constraint; runtime validation and compile-time types cannot drift apart because the types are inferred from the validator; LLM output gets the same validation rigor as user input, which is what makes the fallback in ADR-0006 mechanical rather than judgemental. Link to `0006-llm-guardrails-deterministic-fallback.md`.
- **Consequences → Negative:** the shared package becomes a coupling point that both apps must rebuild against; Zod schemas carry a runtime cost on hot paths; complex conditional schemas are harder to read than plain interfaces.
- **Integration note:** NestJS consumes these schemas through `ValidationPipe` configured with `whitelist: true` and `forbidNonWhitelisted: true`, so unknown fields are stripped and then rejected rather than silently forwarded.
- **Alternatives Considered → Plain TypeScript interfaces:** rejected because they vanish at runtime and provide no protection at the network or LLM boundary, which is exactly where untrusted data arrives.
- **Alternatives Considered → class-validator (the NestJS default):** rejected because its decorator-on-class model does not travel to the frontend cleanly, which would reintroduce duplicate definitions.

- [ ] **Step 2: Write `docs/adr/0005-turborepo-monorepo-tooling.md`**

**This ADR is deliberately unsettled.** Status `Proposed` — not `Accepted` — date `2026-08-13`, deciders `Caio Lima`. It is the only ADR with an `Open Questions` section. Content requirements:

- **Context:** the frontend, backend, and shared packages change together and must stay version-locked; a solo developer cannot afford cross-repository coordination; but monorepo tooling is a decision that is expensive to reverse once CI and caching are built on it.
- **Decision:** "We propose Turborepo as the monorepo task runner, pending a dedicated evaluation before Phase 0 scaffolding begins."
- **Consequences → Positive:** task graph with content-based caching, so unchanged packages skip rebuilds; minimal configuration; works with plain npm/pnpm workspaces rather than replacing them.
- **Consequences → Negative:** Turborepo handles task orchestration but not code generation or dependency-graph enforcement, so module-boundary rules stay a matter of review discipline; remote caching pulls in a hosted dependency if enabled.
- **Alternatives Considered → Nx:** richer generators, dependency-graph visualization, and enforceable module boundaries — which is a genuine draw given ADR-0001's reliance on boundary discipline. Heavier configuration and a more invasive workspace model.
- **Alternatives Considered → Plain pnpm workspaces with no task runner:** zero added tooling and the fewest moving parts; loses incremental caching, which matters once CI runs on every push.
- **Open Questions:** does Nx's enforceable module-boundary linting justify its configuration weight, given that ADR-0001 leans on boundaries holding? Is caching worth any tooling at all before CI exists? This decision is revisited in a dedicated discussion and the status is updated to `Accepted` or superseded then.

- [ ] **Step 3: Write `docs/adr/0006-llm-guardrails-deterministic-fallback.md`**

Status `Accepted`, date `2026-08-13`, deciders `Caio Lima`. Content requirements:

- **Context:** the product uses LLMs for transaction categorization, insight generation, and scenario projection; the domain is a user's money; a plausible-sounding wrong number is worse than no number; model providers have outages and latency spikes.
- **Decision:** "We will treat every LLM call as an untrusted input source: prompts are versioned in git, output is validated against a Zod schema before use, and every call has a deterministic fallback that produces a correct-but-simpler result when the model fails, times out, or returns unparseable output."
- **Mechanism section — spell out the chain-of-verification:** generate → validate schema → correct → deliver; on repeated failure, route to fallback rather than surfacing an error.
- **Mechanism section — the constraints, verbatim:** prompts live in `/packages/prompts/` and change only through a pull request with a regression test; temperature stays `≤ 0.3` for financial analysis and `≤ 0.2` for goal projection, and never exceeds `0.5` on sensitive data; every call logs `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, and `validation_status`.
- **Consequences → Positive:** the product degrades instead of breaking when a provider fails; cost is observable per feature from the first call rather than discovered on a bill; prompt changes are reviewable diffs; a schema-invalid response is a mechanical, testable event rather than a judgement call.
- **Consequences → Negative:** every AI feature is built twice — once with the model and once deterministically — which roughly doubles the cost of each; the fallback path is the one users hit during incidents and the one least exercised in testing, so it needs deliberate test coverage; low temperature reduces output variety.
- **Alternatives Considered → Unconstrained LLM calls with error surfacing:** rejected because an error in a financial dashboard destroys trust, and because unvalidated output would let a hallucinated category or projection reach the user as fact.
- **Alternatives Considered → No LLM features at all:** genuinely considered; deterministic rules cover most categorization. Rejected because auto-categorization quality on unseen merchant strings is where the product differentiates, and the fallback design bounds the risk.

- [ ] **Step 4: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. **The ADR-0002 → ADR-0004 link must now resolve** — no broken-link block at all.

- [ ] **Step 5: Commit**

```bash
git add docs/adr/0004-zod-shared-validation-contract.md docs/adr/0005-turborepo-monorepo-tooling.md docs/adr/0006-llm-guardrails-deterministic-fallback.md
git commit -m "docs: add validation, monorepo tooling, and LLM guardrail ADRs

ADR-0005 is intentionally Proposed rather than Accepted; the monorepo
tooling choice is still open."
```

---

### Task 5: Architecture overview

**Files:**
- Create: `docs/architecture/overview.md`

**Interfaces:**
- Consumes: all six ADR filenames from Tasks 2–4.
- Produces: `docs/architecture/overview.md`, linked from `CLAUDE.md`, `README.md`, `docs/architecture/security.md`, and `docs/architecture/ai-integration.md`.

- [ ] **Step 1: Write the document**

Sections, in order:

1. **Purpose** — one paragraph: what this document covers and what lives in the ADRs instead.

2. **Stack** — this exact table, with the Technology column linking to the relevant ADR:

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | Next.js 14+ (App Router) + React + TypeScript | SSR/SSG, file-based routing, mature ecosystem, straightforward deployment |
| Backend | NestJS 10+ + TypeScript | Modular architecture, native DI, pipes and guards, testable, scalable |
| Database | PostgreSQL 16 + Prisma ORM | Transactions, JSONB, indexing, `pgvector` extension for future AI work, type-safe access |
| Validation | Zod (shared package) | Single contract across frontend and backend, runtime validation plus type inference |
| Local infra | Docker Compose + Turborepo | Reproducible environment, incremental caching, parallel builds |
| Cloud infra | AWS or Azure (future) | Containers identical to local, scale on demand |

3. **Architectural style** — the modular monolith, with the split criteria stated explicitly (latency above 2s, blocked deploys, or a genuine need for independent scaling). Link to `../adr/0001-modular-monolith-over-microservices.md`.

4. **Backend layers** — this exact table, followed by a paragraph on the dependency rule: dependencies point inward, `domain` imports nothing from the other three layers, and repository interfaces are declared in `domain` but implemented in `infrastructure`.

| Layer | Responsibility | Example |
|---|---|---|
| `domain/` | Pure rules, entities, value objects, repository interfaces | `Transaction.value > 0`, `Budget.isWithinLimit()` |
| `application/` | Use cases, DTOs, rule orchestration | `CreateTransactionUseCase`, `CalculateBudgetProjection` |
| `infrastructure/` | Database (Prisma), parsers (OFX/CSV), LLM clients, email, queues | `PrismaTransactionRepo`, `OpenAIProvider`, `BullMQQueue` |
| `interface/` | Controllers, guards, pipes, OpenAPI/Swagger | `TransactionController`, `JwtAuthGuard` |

5. **Repository layout** — this exact fenced block, with a sentence on each entry:

```
bolso-firme/
├── apps/
│   ├── web/          # Next.js frontend
│   └── api/          # NestJS backend
├── packages/
│   ├── shared/       # Zod schemas, types, utils, constants
│   ├── prompts/      # Versioned LLM prompts (v1.0, v1.1, ...)
│   └── config/       # ESLint, Prettier, TSConfig, Jest/Vitest
├── docker-compose.yml
└── turbo.json
```

6. **Related decisions** — a bulleted list linking all six ADRs by relative path with a one-line summary each.

- [ ] **Step 2: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. No broken links — verify each `../adr/...` path resolves from `docs/architecture/`.

- [ ] **Step 3: Commit**

```bash
git add docs/architecture/overview.md
git commit -m "docs: add architecture overview"
```

---

### Task 6: Security architecture

**Files:**
- Create: `docs/architecture/security.md`

**Interfaces:**
- Consumes: `docs/architecture/overview.md` (Task 5) for the layer vocabulary it references.
- Produces: `docs/architecture/security.md`, linked from `CLAUDE.md` and `README.md`.

- [ ] **Step 1: Write the document**

Sections:

1. **Purpose and posture** — one paragraph: security is shift-left, meaning controls are designed with each module rather than audited afterward. Note that this describes the target design; controls land phase by phase per `../product/roadmap.md`.

2. **Controls** — this exact table:

| Domain | Implementation |
|---|---|
| Authentication | JWT + refresh token (`HttpOnly`, `SameSite=Strict`, automatic rotation) |
| Authorization | RBAC via decorators (`@Roles('admin')`), per-route guards |
| Financial data | Encryption at rest (AES-256), masking in logs, guaranteed LGPD deletion |
| Secrets | `.env` locally → AWS Secrets Manager or Vault in production. Zero hardcoding |
| Validation | Zod + NestJS `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true` |
| Threats | STRIDE threat modeling per module. Rate limiting, restricted CORS, input sanitization |
| Audit | Structured JSON logs, `x-request-id` per flow, immutable `audit_log` table |

3. **Authentication flow** — prose describing refresh-token rotation: access tokens are short-lived and held in memory, refresh tokens live in an `HttpOnly` cookie, each refresh issues a new token and invalidates its predecessor, and reuse of an invalidated refresh token is treated as compromise and revokes the session family.

4. **Data protection** — what counts as sensitive (transaction amounts and descriptions, account identifiers, imported statement files), AES-256 at rest, masking rules for logs, and the LGPD deletion guarantee: a deletion request removes personal data while the immutable `audit_log` retains only non-identifying records of the action.

5. **Threat modeling** — STRIDE applied per module, performed when a module is designed rather than after it ships. One concrete worked example: the statement-import flow, where spoofed or malicious OFX/CSV input is the tampering vector, mitigated by parsing into a Zod-validated shape before any persistence and never evaluating file content.

6. **Auditability** — structured JSON logging, `x-request-id` propagated across the whole request flow including LLM calls, and the append-only `audit_log` table.

7. **Multi-tenant isolation** — a forward-looking paragraph: Phase 5 introduces shared budgets, at which point every query must be scoped by owner and cross-tenant leakage becomes the primary acceptance criterion. Link to `../product/roadmap.md`.

- [ ] **Step 2: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. The `../product/roadmap.md` links will report broken until Task 8 — **expected here**, and they must resolve by Task 8's check.

- [ ] **Step 3: Commit**

```bash
git add docs/architecture/security.md
git commit -m "docs: add security architecture"
```

---

### Task 7: AI integration architecture

This is the document that most distinguishes the repository. It must read as engineering, not as enthusiasm.

**Files:**
- Create: `docs/architecture/ai-integration.md`

**Interfaces:**
- Consumes: `docs/adr/0006-llm-guardrails-deterministic-fallback.md` (Task 4).
- Produces: `docs/architecture/ai-integration.md`, linked from `CLAUDE.md`, `README.md`, and `docs/engineering/guardrails.md`.

- [ ] **Step 1: Write the document**

Sections:

1. **Principle** — one paragraph stating the governing rule: an LLM is an untrusted input source that happens to be expensive. Every call is validated, bounded, observable, and has a deterministic path that runs when it fails. Link to `../adr/0006-llm-guardrails-deterministic-fallback.md`.

2. **AI in the product** — this exact table, then a subsection per feature:

| Feature | Technical implementation |
|---|---|
| Auto-categorization | OFX/CSV parser → extract description → LLM with versioned prompt → fall back to a static rule when `confidence < threshold` |
| Intelligent insights | Monthly aggregation → hierarchical summary prompt → Zod-validated JSON → conditional display |
| Goal projection | Deterministic calculation + scenario simulation via LLM (temperature `≤ 0.2`) |

   - *Auto-categorization:* the deterministic fallback is a merchant-string rule table; the LLM only handles strings the table misses, so its failure degrades the feature to the rule table rather than breaking import.
   - *Intelligent insights:* output is display-only and never feeds a calculation; if schema validation fails, the insight panel is simply not rendered — the dashboard does not show a degraded or partial insight.
   - *Goal projection:* the projected number is always computed deterministically. The LLM only narrates scenarios around that number and can never alter it.

3. **AI in development** — this exact table, then a paragraph on why development-time discipline is documented at all: the repository is meant to demonstrate that generated code is reviewed, explained, and tested rather than pasted.

| Practice | Rule |
|---|---|
| Prompt registry | Critical prompts versioned in git (`/packages/prompts/`), never in loose variables |
| Chain-of-verification | Generate → validate schema → correct → deliver. On failure, route to fallback |
| Temperature | `≤ 0.3` for analysis and finance. Never `> 0.5` on sensitive data |
| Observability | Structured log: `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status` |
| Mandatory fallback | On LLM timeout, error, or invalid output → deterministic rule or smaller model. Never blocks the UX |

4. **Call lifecycle** — a fenced diagram plus prose walking each stage:

```
request
  → load versioned prompt from packages/prompts
  → call model (temperature ≤ 0.3, timeout enforced)
  → parse response
  → validate against Zod schema
      ├── valid   → return result
      └── invalid → one correction attempt
                      ├── valid   → return result
                      └── invalid → deterministic fallback
  → log tokens_in, tokens_out, cost_usd, latency_ms, validation_status
```

   State explicitly that the logging stage runs on every path, including fallback, so fallback rate is measurable.

5. **Prompt versioning** — prompts are files, not strings; each has a semantic version (`v1.0`, `v1.1`); changing one requires a pull request with a regression test that pins expected output shape for a fixed input set.

6. **Cost and quality metrics** — what is tracked per feature (tokens, USD cost per month, schema validation rate, fallback rate) and the rule that a feature without these metrics does not ship. Link to `../engineering/guardrails.md`.

- [ ] **Step 2: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. The `../engineering/guardrails.md` link reports broken until Task 9 — **expected here**.

- [ ] **Step 3: Commit**

```bash
git add docs/architecture/ai-integration.md
git commit -m "docs: add AI integration architecture"
```

---

### Task 8: Product vision and roadmap

**Files:**
- Create: `docs/product/vision.md`
- Create: `docs/product/roadmap.md`

**Interfaces:**
- Consumes: nothing from earlier tasks beyond the check script.
- Produces: `docs/product/roadmap.md`, which resolves the forward links left by `docs/architecture/security.md` in Task 6.

- [ ] **Step 1: Write `docs/product/vision.md`**

Sections:

1. **Problem** — people lose control of their finances through a lack of visibility, structure, and motivation. Expand into a paragraph naming the concrete failure: spending data exists but is scattered across accounts, so no single view answers "am I on track this month".
2. **Solution** — a macro-to-micro dashboard, per-category budgeting, visible goals, and a consolidated portfolio view.
3. **Differentiator** — progressive clarity through temporal zoom (year → month → week → transaction), motivational design, and the unification of spending, goals, and investments in one product rather than three.
4. **Engineering objective** — build with production rigor from day one. Every feature ships with tests, schema validation, observability, and a deterministic fallback. LLMs are controlled copilots, never blind generators. State plainly that this is a portfolio project where *how* it is built is part of the deliverable. Link to `../engineering/guardrails.md`.
5. **Scope boundary** — a short honest paragraph: the product targets an individual managing personal finances, with shared/household budgets arriving in Phase 5. Personas beyond that are deliberately not defined yet. Link to `roadmap.md`.

- [ ] **Step 2: Write `docs/product/roadmap.md`**

An intro paragraph stating that each phase becomes its own design spec and implementation plan when started — this document is the map, not the execution plan — followed by this exact table:

| Phase | Focus | Technical deliverables | Acceptance criteria |
|---|---|---|---|
| 0 | Foundation & CI/CD | Monorepo, Docker, Prisma, JWT auth, shared Zod package, GitHub Actions | CI green, coverage ≥ 70%, `.env.example` with no secrets |
| 1 | Transactions & Dashboard | Transaction CRUD, CSV/OFX parser, TanStack Query, basic Recharts | Endpoint validated, import working, p95 < 1s |
| 2 | Budget & Alerts | Custom categories, percentages, DDD rules, notifications | Alert fires in real time, calculation accurate, tests ≥ 80% |
| 3 | Goals & Investments | Manual portfolio, visual projection, LLM auto-categorization (gated) | Fallback active, 100% Zod validation, token cost logged |
| 4 | Premium & Payments | Stripe/Asaas, feature flags, freemium gates, exportable reports | Idempotent checkout, webhook retry, audit log |
| 5 | Multi-user | Groups, RBAC, invitations, shared budgets, audit trail | Permissions isolated, no cross-tenant leakage |
| 6 | Optimization & Scale | Redis cache, OpenTelemetry, rate limiting, K8s/AWS preparation | Latency < 500ms, zero secrets in the repository, metrics visible |
| 7+ | Mobile & Open Finance | React Native/Expo, BCB certification, offline sync | Code reuse ≥ 70%, LGPD compliance, offline fallback |

Then an **Estimates** section: MVP (Phases 0–2) in 8–10 weeks; the full product through Phase 6 in 5–6 months; mobile and Open Finance adding 3–4 months. Add one sentence noting these assume solo part-time development and are planning aids, not commitments.

- [ ] **Step 3: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1`, Portuguese findings only from `docs/bolso-firme-escopo.md`. **The `../product/roadmap.md` links from `docs/architecture/security.md` must now resolve.** The only remaining broken link should be `../engineering/guardrails.md`, referenced from `ai-integration.md` and `vision.md`.

- [ ] **Step 4: Commit**

```bash
git add docs/product/vision.md docs/product/roadmap.md
git commit -m "docs: add product vision and phased roadmap"
```

---

### Task 9: Engineering guardrails

**Files:**
- Create: `docs/engineering/guardrails.md`

**Interfaces:**
- Consumes: `docs/adr/0006-llm-guardrails-deterministic-fallback.md`, `docs/architecture/ai-integration.md`.
- Produces: `docs/engineering/guardrails.md`, resolving every remaining forward link in the documentation set.

- [ ] **Step 1: Write the document**

Sections:

1. **Purpose** — one paragraph: this is the contract the project holds itself to, written down so that "we were moving fast" is never an available excuse. Note that these gates are aspirational until Phase 0 builds the pipeline that enforces them.

2. **The six rules** — a numbered list, each with a sentence of rationale:
   1. **No merge without validation:** `test → lint → schema validation → manual code review`.
   2. **Versioned prompts:** critical prompts live in git under `/packages/prompts/`; changes require a pull request and a regression test.
   3. **Metrics from day one:** `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status`. No metrics means no production.
   4. **Deterministic fallback:** when an LLM fails, route to a static rule or a smaller model. It never blocks the UX.
   5. **Mandatory explainability:** if a generated line cannot be explained, it does not get merged. Ask for the explanation, understand it, adapt it.
   6. **Non-negotiable CI/CD:** `lint → test:coverage(≥70%) → build → scan → deploy`. Green merges, red blocks.

3. **Definition of done** — a checklist a pull request must satisfy: behavior covered by tests; cross-boundary shapes validated by a Zod schema; no secret in the diff; public behavior change reflected in documentation; any new LLM call has a fallback and emits the five observability fields; the author can explain every line.

4. **CI/CD pipeline** — each stage in order with what it gates and what failure means. Note that the coverage floor is 70% overall, and Phase 2 raises its own target to 80%. Link to `../product/roadmap.md`.

5. **Metrics** — this exact table:

| Type | Metric | Tooling |
|---|---|---|
| Product | Free→premium conversion, D30 retention, dashboard activation | PostHog / Mixpanel |
| Backend | p95 latency, 5xx error rate, req/s throughput, DB pool usage | Pino + OpenTelemetry + Grafana |
| AI/LLM | Tokens per feature, USD cost per month, schema validation rate, fallback rate | LangSmith / custom logger |
| Quality | Coverage %, PR review time, CI failure rate, dependency vulnerabilities | GitHub Actions + SonarQube (future) |

6. **Documentation checks** — describe `scripts/check-docs.sh`, what its three checks are, and how to run it. Note the two sanctioned `pending Phase 0` placeholders.

7. **Related reading** — links to `../architecture/ai-integration.md` and `../adr/0006-llm-guardrails-deterministic-fallback.md`.

- [ ] **Step 2: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1` with **Portuguese findings from `docs/bolso-firme-escopo.md` as the only remaining category**. No broken links anywhere in the set.

- [ ] **Step 3: Commit**

```bash
git add docs/engineering/guardrails.md
git commit -m "docs: add engineering guardrails and quality gates"
```

---

### Task 10: CLAUDE.md and README.md

**Files:**
- Create: `CLAUDE.md`
- Create: `README.md`

**Interfaces:**
- Consumes: every document created in Tasks 2–9.
- Produces: the two repository-root entry points. Both are one directory above `docs/`, so links take the form `docs/...` with no `../` prefix — a common source of broken links here.

- [ ] **Step 1: Write `CLAUDE.md`**

Sections:

1. **Project** — two to three sentences on what Bolso Firme is, linking to `docs/product/vision.md`.
2. **Engineering philosophy** — production rigor from day one; LLMs are controlled copilots; zero vibe coding. Three or four sentences, linking to `docs/engineering/guardrails.md` for the full contract.
3. **Tech stack** — a compact table (Layer / Technology / ADR) with the ADR column linking to `docs/adr/...`.
4. **Architecture** — modular monolith and the four DDD layers named explicitly, linking to `docs/architecture/overview.md`. One sentence on the dependency rule.
5. **Repository structure** — the same layout block as `docs/architecture/overview.md`, with a note that it describes the target structure and lands in Phase 0.
6. **Non-negotiables** — an inline checklist, stated in full so it holds without opening another file:
   - No merge without `test → lint → schema validation → manual code review`
   - Prompts live in `/packages/prompts/` and are versioned; changes need a PR and a regression test
   - Every LLM call has a deterministic fallback and logs `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status`
   - Temperature `≤ 0.3` on financial analysis, `≤ 0.2` on goal projection
   - No hardcoded secrets, ever — `.env` locally, a secrets manager in production
   - Cross-boundary shapes are Zod schemas in the shared package; types are inferred from them
   - Code that cannot be explained does not get merged
7. **Commands** — a section whose body is exactly: `TBD — pending Phase 0 scaffolding.` (The `pending Phase 0` string is what allows the check script to accept this `TBD`.)
8. **Documentation map** — a bulleted index of every document with a one-line description and a relative link.
9. **Working agreements** — documentation, code comments, and commit messages are written in English; conversation with the maintainer may be in Portuguese; commits follow Conventional Commits; each roadmap phase gets its own design spec and implementation plan before implementation starts.

- [ ] **Step 2: Write `README.md`**

Sections:

1. **Title and tagline** — `# Bolso Firme` and one line: personal finance management built with production engineering rigor.
2. **Badges** — a commented-out HTML block holding build and coverage badge markup, with a note that they activate in Phase 0. Do not add live badges pointing at pipelines that do not exist.
3. **The problem and the approach** — two short paragraphs condensed from `docs/product/vision.md`, linking to it.
4. **Why this repository is interesting** — a short bulleted list aimed at a technical reader: architectural decisions recorded as ADRs with rejected alternatives; LLM integration designed around validation and deterministic fallback rather than raw API calls; DDD layering in a modular monolith with explicit criteria for when to split it; quality gates written down before the code exists.
5. **Stack** — the same stack table as `docs/architecture/overview.md`.
6. **Documentation** — a table with two columns (Document, What it covers) linking to every file under `docs/`, grouped as Product, Architecture, Decisions, Engineering.
7. **Project status** — plainly stated: the documentation foundation is complete and implementation begins at Phase 0. Link to `docs/product/roadmap.md`.
8. **Running locally** — a section whose body is exactly: `TBD — pending Phase 0 scaffolding.`
9. **License** — MIT.

- [ ] **Step 3: Run the check**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: exit `1` with Portuguese findings from `docs/bolso-firme-escopo.md` only. Both `TBD` markers must be accepted because each sits on a line containing `pending Phase 0` — if a placeholder finding appears, the marker and the label are on different lines; put them on one line.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "docs: add operational context and repository README"
```

---

### Task 11: Retire the superseded sources and verify the set

**Files:**
- Delete: `docs/bolso-firme-escopo.md` (tracked)
- Delete: `.qwen/` (untracked, git-ignored)
- Delete: `test.ts` (untracked, empty)
- Add: `.claude/settings.json` (untracked)

**Interfaces:**
- Consumes: the complete documentation set from Tasks 2–10.
- Produces: a clean working tree and `./scripts/check-docs.sh` exiting `0`.

- [ ] **Step 1: Confirm the scope document's content has been fully migrated**

Before deleting, read `docs/bolso-firme-escopo.md` one final time against the new set. Every section must have a home:

| Scope section | Migrated to |
|---|---|
| §1 Vision & objective | `docs/product/vision.md` |
| §2 Stack & architecture | `docs/architecture/overview.md`, ADR-0001, ADR-0002, ADR-0003, ADR-0005 |
| §3 Security & compliance | `docs/architecture/security.md` |
| §4 AI integration | `docs/architecture/ai-integration.md`, ADR-0006 |
| §5 Monorepo & DDD layers | `docs/architecture/overview.md` |
| §6 Roadmap | `docs/product/roadmap.md` |
| §7 Anti-vibe-coding guardrails | `docs/engineering/guardrails.md` |
| §8 Metrics & observability | `docs/engineering/guardrails.md` |

If anything is missing, add it to the appropriate document before proceeding. The content remains recoverable from git history after deletion, but the point is to not need it.

- [ ] **Step 2: Delete the superseded files**

```bash
git rm docs/bolso-firme-escopo.md
rm -rf .qwen
rm -f test.ts
```

- [ ] **Step 3: Run the check — it must now be green**

Run: `./scripts/check-docs.sh; echo "exit=$?"`
Expected: `check-docs: clean` and `exit=0`. This is the first fully passing run; if any finding remains, fix it before committing.

- [ ] **Step 4: Verify the working tree and file set**

```bash
git status --short
find docs CLAUDE.md README.md scripts -type f | sort
```

Expected: `git status --short` shows only the staged deletion and the untracked `.claude/`. The `find` output lists exactly the 16 files from the File Structure table plus the two `docs/superpowers/` process documents.

- [ ] **Step 5: Commit**

```bash
git add .claude/settings.json
git commit -m "docs: retire the Portuguese scope document and Qwen context

The scope document's content now lives in docs/product, docs/architecture,
docs/adr, and docs/engineering. Removes the stray empty test.ts and tracks
the Claude Code plugin settings so contributors get the same tooling."
```

- [ ] **Step 6: Final read-through**

Open `README.md` and follow every link in the documentation table, then open `CLAUDE.md` and do the same. The script proves the paths resolve; this step confirms each link lands on a document that says what the link promised. Fix any mismatch and amend the commit.

---

## Self-Review

**Spec coverage.** Every item in the spec's File Structure has a task: check script (Task 1, an addition that implements the spec's §6 verification list rather than new scope); ADRs (Tasks 2–4); architecture (Tasks 5–7); product (Task 8); guardrails (Task 9); `CLAUDE.md` and `README.md` (Task 10); removals and `.claude/settings.json` (Task 11). Spec §6's four verification criteria map to: link resolution (script check 1 + Task 11 Step 6), placeholder discipline (script check 2), no Portuguese (script check 3), and no dropped scope content (Task 11 Step 1's migration table). ADR-0005's `Proposed` status is stated in the Global Constraints, in Task 4 Step 2, and in the commit message.

**Placeholder scan.** The only `TBD` strings in this plan are the two the spec sanctions, and both are specified as exact literal text on a line containing `pending Phase 0`. No task says "similar to Task N" — the ADR content briefs are written out individually. No step defers content to the implementer's judgement.

**Type consistency.** Path names are consistent throughout: `scripts/check-docs.sh` is invoked identically in Tasks 1–11; ADR filenames in the File Structure table match the create-paths in Tasks 2–4 and the link targets in Tasks 5, 7, 9, and 10. Relative link depth is called out where it changes — `../adr/` and `../product/` from inside `docs/architecture/`, versus bare `docs/` from the repository root in Task 10.

**Known-failing intermediate states.** Three tasks deliberately end with a broken forward link, each stated in that task's expected output and each resolved by a named later task: ADR-0002 → ADR-0004 (resolved in Task 4), `security.md` → `roadmap.md` (resolved in Task 8), and `ai-integration.md`/`vision.md` → `guardrails.md` (resolved in Task 9). Task 9's check is the first with no broken links, and Task 11's is the first fully green run.

**Script verified before planning.** The check script was run against the current repository while this plan was written. It correctly exits `1` reporting 43 Portuguese lines in `docs/bolso-firme-escopo.md` and nothing else, which is exactly the baseline Task 1 Step 3 predicts. That trial also caught a defect now fixed in the plan: the file list originally used `git ls-files`, which sees only tracked files — since the script runs *before* each task's commit, every newly written document would have been skipped rather than checked. The `--others --exclude-standard` flags fix it, confirmed by a scratch file appearing in the listing only after the change.
