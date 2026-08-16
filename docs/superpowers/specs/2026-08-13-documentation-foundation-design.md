# Design: Documentation Foundation

**Date:** 2026-08-13
**Status:** Approved
**Scope:** Documentation only — no product code.

---

## 1. Context

`Bolso Firme` is a personal finance product built as a solo project with two
goals held at the same time: a working product, and a public repository that
demonstrates production-grade software engineering to an international
audience.

Two documents describe the project today:

- `docs/bolso-firme-escopo.md` — the technical scope (v4.0), in Portuguese.
  Authoritative on content, but the tables are malformed from a bad conversion.
- `.qwen/agents/QWEN.md` — an agent context file written for Qwen Code.

Analysis of both files shows `QWEN.md` is a strict subset of the scope
document: every section it contains (engineering vision, stack, security, AI
integration, monorepo structure, guardrails, metrics) is a condensed
restatement of the corresponding scope section, with no unique content. The
root-level `QWEN.md` and the five `.github/workflows/qwen-*.yml` files have
already been deleted in the working tree.

Therefore the "merge" is not a content reconciliation. It is a migration: the
scope document is the single source of truth, its content is restructured into
a documentation set in English, and the Qwen-specific operating context is
replaced by a `CLAUDE.md` equivalent.

## 2. Goals

1. Establish `CLAUDE.md` as the operational context for development.
2. Restructure the Portuguese scope document into an English documentation set
   covering product, architecture, decisions, and engineering practice.
3. Record the architectural decisions already implied by the scope as ADRs with
   real trade-offs and rejected alternatives.
4. Give the repository a portfolio-quality front door.

**Non-goals:** scaffolding the monorepo, writing product code, or setting up
CI/CD. Those belong to Phase 0 and get their own spec and plan.

## 3. Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Source of truth | `docs/bolso-firme-escopo.md` | Explicit user direction; `QWEN.md` adds nothing |
| Documentation language | English (all files) | Repository targets an international audience |
| Conversation language | Portuguese | Unchanged; a working preference, not a doc policy |
| Scope document fate | Rewritten in English, original deleted | Content migrates to `docs/product/` and `docs/adr/`; keeping a malformed Portuguese duplicate creates drift |
| Depth in this pass | Full prose, not skeleton | The repository should read as complete to anyone opening it today |
| ADR coverage | Retroactive ADRs for decisions already made | Documenting reasoning behind "obvious" choices is the portfolio value |

## 4. File Structure

```
bolsoFirme/
├── README.md
├── CLAUDE.md
└── docs/
    ├── product/
    │   ├── vision.md
    │   └── roadmap.md
    ├── architecture/
    │   ├── overview.md
    │   ├── security.md
    │   └── ai-integration.md
    ├── adr/
    │   ├── template.md
    │   ├── 0001-modular-monolith-over-microservices.md
    │   ├── 0002-nextjs-nestjs-typescript-stack.md
    │   ├── 0003-postgresql-prisma-orm.md
    │   ├── 0004-zod-shared-validation-contract.md
    │   ├── 0005-turborepo-monorepo-tooling.md
    │   └── 0006-llm-guardrails-deterministic-fallback.md
    └── engineering/
        └── guardrails.md
```

**Removed:** `docs/bolso-firme-escopo.md` (tracked — its deletion is part of this
commit), plus `.qwen/` and the stray empty `test.ts`. The latter two are
untracked, so removing them only cleans the working tree. The already-staged
deletions of `QWEN.md` and the five `.github/workflows/qwen-*.yml` files are
committed as part of this work.

`.claude/settings.json` is untracked and currently records only enabled plugins.
It gets committed alongside the documentation — it is harmless to publish and
tells a contributor which tooling the project expects.

## 5. Document Contents

### CLAUDE.md (root, English)

The operational contract for development sessions. Sections:

- **Project summary** — two to three sentences, linking to `docs/product/vision.md`
- **Engineering philosophy** — production rigor from day one; LLMs as controlled
  copilots; zero vibe coding. Condensed, linking to `docs/engineering/guardrails.md`
- **Tech stack** — table with each row linking to its ADR
- **Architecture pattern** — modular monolith, DDD layers
  (`domain` / `application` / `infrastructure` / `interface`), linking to
  `docs/architecture/overview.md`
- **Repository structure** — monorepo layout map
- **Non-negotiables** — the inline checklist that must hold without re-reading
  any other file: no merge without test → lint → schema validation → manual
  review; prompts versioned in git; deterministic fallback mandatory for every
  LLM call; temperature ≤ 0.3 on financial data; no hardcoded secrets
- **Commands** — marked `TBD` until Phase 0 scaffolding lands
- **Language policy** — documentation, code comments, and commit messages in
  English; conversation may be Portuguese

### docs/product/vision.md

Problem, solution, and differentiator from scope §1, rewritten as clean English
prose. Engineering objective statement. Brief user framing — kept short rather
than inventing personas the scope never defined.

### docs/product/roadmap.md

Phases 0 through 7+ as a table (focus, technical deliverables, acceptance
criteria), translated from scope §6. Includes the realistic estimate (MVP in
8–10 weeks; full product through Phase 6 in 5–6 months; mobile and Open Finance
adding 3–4 months). States explicitly that each phase gets its own spec and
implementation plan when started — this roadmap is the map, not the execution
plan.

### docs/architecture/overview.md

Stack table with rationale (scope §2). Monorepo layout. DDD layer
responsibilities with concrete examples (scope §5). The modular-monolith
decision with its explicit split criteria: service extraction happens only when
metrics justify it — latency above 2s, blocked deploys, or a genuine need for
independent scaling.

### docs/architecture/security.md

From scope §3: JWT with refresh token rotation (HttpOnly, SameSite=Strict);
RBAC through NestJS decorators; AES-256 encryption at rest for financial data
with log masking and guaranteed LGPD deletion; secrets management progressing
from `.env` locally to AWS Secrets Manager or Vault in production; STRIDE threat
modeling per module; rate limiting, restricted CORS, input sanitization;
structured JSON logging with `x-request-id` propagation and an immutable
`audit_log` table.

### docs/architecture/ai-integration.md

Split in two halves.

*AI in the product* (scope §4): auto-categorization (OFX/CSV parser → LLM with
versioned prompt → static-rule fallback below confidence threshold), intelligent
insights (monthly aggregation → hierarchical summary prompt → Zod-validated JSON
→ conditional display), goal projection (deterministic calculation plus scenario
simulation at temperature ≤ 0.2).

*AI in development*: prompt registry in `/packages/prompts/`,
chain-of-verification (generate → validate schema → correct → deliver),
temperature ceilings, structured observability (`tokens_in`, `tokens_out`,
`cost_usd`, `latency_ms`, `validation_status`), mandatory fallback.

This is the document that most differentiates the repository — it shows
responsible LLM engineering rather than an API call.

### docs/adr/

Template sections: Status, Context, Decision, Consequences, Alternatives
Considered.

| ADR | Decision | Rejected alternatives |
|---|---|---|
| 0001 | Modular monolith over microservices | Microservices from day one — operational overhead unjustified for a solo developer with no metrics demanding a split; explicit split criteria recorded |
| 0002 | Next.js + NestJS + TypeScript | Remix / SvelteKit on the frontend; Express / Fastify on the backend — weaker DI and testability story for the backend, less mature SSR for the frontend |
| 0003 | PostgreSQL + Prisma ORM | MongoDB (financial data needs ACID transactions); TypeORM / Drizzle (Prisma wins on DX, type safety, and a pgvector path) |
| 0004 | Zod as the shared validation contract | Plain TypeScript types with no runtime validation; class-validator in isolation — Zod gives one contract across frontend and backend |
| 0005 | Turborepo for monorepo tooling | Multi-repo; Nx |
| 0006 | LLM guardrails: deterministic fallback and schema validation | Unconstrained LLM use without fallback — unacceptable risk in a financial domain |

**ADR-0005 carries status `Proposed`, not `Accepted`.** The monorepo tooling
choice is explicitly open for re-discussion before it becomes final. The ADR
includes an "Open Questions" section recording that Turborepo, Nx, and a
plain-workspaces approach are still live options, and that the decision will be
revisited in a dedicated conversation. Every other ADR is `Accepted`.

### docs/engineering/guardrails.md

The anti-vibe-coding contract, from scope §7 and §8:

- Non-negotiable CI/CD pipeline: lint → test with coverage ≥ 70% → build → scan → deploy
- Definition of done per pull request: test, lint, schema validation, manual review
- Prompt versioning policy — changes require a PR and a regression test
- Observability requirements for AI features; no LLM feature ships without
  token, cost, latency, and validation-status metrics
- Mandatory explainability — an unexplainable generated line does not get merged
- Metrics tables for product, backend, AI, and quality

### README.md

Title and tagline, build and coverage badges (placeholders until the pipelines
exist), condensed problem and solution, stack table, navigation into `docs/`,
screenshot placeholder, local setup section marked pending Phase 0, license.

## 6. Verification

Documentation-only work, so verification is review rather than test execution:

- Every internal link resolves to a file that exists
- No section carries an unintended `TBD`; the two deliberate ones (CLAUDE.md
  commands, README setup) are labeled as pending Phase 0
- No Portuguese text remains in any committed documentation file
- No content from `docs/bolso-firme-escopo.md` is dropped without being either
  migrated or consciously discarded
- ADR-0005 reads as open, not settled

## 7. Next Step

After this foundation is committed and reviewed, Phase 0 (monorepo scaffolding,
Docker, Prisma, JWT auth, shared Zod package, GitHub Actions) is brainstormed as
its own architectural task with its own spec and implementation plan. The
ADR-0005 re-discussion happens before or during that work, since the tooling
choice shapes the scaffolding.
