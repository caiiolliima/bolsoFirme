# Bolso Firme

Personal finance management built with production engineering rigor.

<!--
Build and coverage badges live here. They are commented out on purpose: the
pipelines they point at do not exist yet, and a badge for a pipeline that was
never run is worse than no badge at all. Both activate in Phase 0, once GitHub
Actions runs lint, tests, and the coverage gate on every push.

[![CI](https://github.com/caiolima/bolso-firme/actions/workflows/ci.yml/badge.svg)](https://github.com/caiolima/bolso-firme/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/coverage-70%25-informational)](https://github.com/caiolima/bolso-firme)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](https://opensource.org/licenses/MIT)
-->

## The problem and the approach

People lose control of their finances through a lack of visibility, structure,
and motivation. The data almost always exists already, and it still answers
nothing: spending is scattered across a salary account, a second bank, several
credit cards with different closing dates, a digital wallet, and the occasional
cash withdrawal. Every one of those sources can produce a statement, and every
statement is honest about its own slice, but none of them answers the only
question that matters in the middle of the month, which is whether the person is
on track. Answering it by hand means exporting files, reconciling transfers
between one's own accounts, and rebuilding the same spreadsheet every thirty
days. Most people do it once and never again.

Bolso Firme consolidates those sources into a single view and adds the two
things a statement cannot provide: per-category budgets with a running total, so
a limit means something, and visible goals sitting next to the spending that
funds them. Navigation moves from the macro to the micro through temporal zoom,
from a year down to a month, a week, and finally an individual transaction, so
the dashboard answers the broad question first and only then explains itself.
The full articulation of the problem, the solution, and the scope boundary lives
in [Product Vision](docs/product/vision.md).

## Why this repository is interesting

This is a portfolio project, and *how* it is built is part of the deliverable.
For a technical reader, these are the parts worth opening:

- **Architectural decisions are recorded, not assumed.** Six ADRs state the
  context, the decision, the consequences that hurt, and the alternatives that
  were rejected with the specific trade-off that killed each one. ADR-0005 is
  still `Proposed` and carries open questions, because pretending a decision is
  settled when it is not is the failure mode ADRs exist to prevent.
- **LLM integration is designed around validation and fallback, not around API
  calls.** Every model call is treated as an untrusted input source: prompts are
  versioned files under `/packages/prompts/`, output is validated against a Zod
  schema before anything consumes it, temperature is bounded, and each call has
  a deterministic path that runs when the model fails, times out, or returns
  something unparseable. A plausible-sounding wrong number in a financial
  product is worse than no number.
- **DDD layering inside a modular monolith, with the exit criteria written
  down.** The backend is one deployable with `domain`, `application`,
  `infrastructure`, and `interface` layers and an inward-pointing dependency
  rule. The conditions that would justify extracting services are stated up
  front: p95 latency above 2s, deploys blocked by unrelated modules, or a module
  that genuinely needs to scale independently.
- **Quality gates exist before the code does.** The merge gate
  (`test → lint → schema validation → manual code review`), the CI pipeline
  (`lint → test:coverage(≥70%) → build → scan → deploy`), the observability
  fields every LLM call emits, and the definition of done are all written down,
  so "we were moving fast" is never an available excuse.
- **The documentation validates itself.** `scripts/check-docs.sh` checks that
  every relative link resolves, that no unlabeled placeholder survives, and that
  no untranslated prose leaked into the English documentation set.

## Stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | Next.js 14+ (App Router) + React + TypeScript | SSR/SSG, file-based routing, mature ecosystem, straightforward deployment |
| Backend | NestJS 10+ + TypeScript | Modular architecture, native DI, pipes and guards, testable, scalable |
| Database | PostgreSQL 16 + Prisma ORM | Transactions, JSONB, indexing, `pgvector` extension for future AI work, type-safe access |
| Validation | Zod (shared package) | Single contract across frontend and backend, runtime validation plus type inference |
| Local infra | Docker Compose + Turborepo | Reproducible environment, incremental caching, parallel builds |
| Cloud infra | AWS or Azure (future) | Containers identical to local, scale on demand |

Every row above is backed by a decision record; see the Decisions group below
for the reasoning and the rejected alternatives.

## Documentation

### Product

| Document | What it covers |
|---|---|
| [Product Vision](docs/product/vision.md) | The problem, the solution, the differentiator, the engineering objective, and the current scope boundary |
| [Product Roadmap](docs/product/roadmap.md) | Phases 0 through 7+ with technical deliverables, acceptance criteria, and planning estimates |

### Architecture

| Document | What it covers |
|---|---|
| [Architecture Overview](docs/architecture/overview.md) | Stack, the modular monolith and its split criteria, the four DDD layers and the dependency rule, and the target monorepo layout |
| [Security Architecture](docs/architecture/security.md) | Authentication and authorization, encryption and secret handling, STRIDE threat modeling, auditability, and multi-tenant isolation |
| [AI Integration Architecture](docs/architecture/ai-integration.md) | LLM features in the product, LLM discipline in development, the call lifecycle, prompt versioning, and cost and quality metrics |

### Decisions

| Document | What it covers |
|---|---|
| [ADR-0001: Modular monolith over microservices](docs/adr/0001-modular-monolith-over-microservices.md) | Why the backend ships as one deployable, and the measured conditions that would justify splitting it |
| [ADR-0002: TypeScript everywhere with Next.js and NestJS](docs/adr/0002-nextjs-nestjs-typescript-stack.md) | Frontend, backend, and language selection for a solo developer working across the whole stack |
| [ADR-0003: PostgreSQL 16 with Prisma ORM](docs/adr/0003-postgresql-prisma-orm.md) | The persistence engine and the data-access layer, chosen for transactional correctness over financial data |
| [ADR-0004: Zod as the shared validation contract](docs/adr/0004-zod-shared-validation-contract.md) | One schema per cross-boundary shape, with TypeScript types inferred from the validator rather than declared beside it |
| [ADR-0005: Turborepo as monorepo tooling](docs/adr/0005-turborepo-monorepo-tooling.md) | Monorepo task running and caching. Still `Proposed`, with open questions to resolve before Phase 0 scaffolding |
| [ADR-0006: LLM guardrails and deterministic fallback](docs/adr/0006-llm-guardrails-deterministic-fallback.md) | How model output is constrained, validated, bounded, observed, and replaced when it fails |
| [ADR template](docs/adr/template.md) | The format every decision record follows, including the alternatives and consequences sections |

### Engineering

| Document | What it covers |
|---|---|
| [Engineering Guardrails](docs/engineering/guardrails.md) | The six non-negotiable rules, the definition of done, the CI/CD pipeline and coverage floor, the metrics tracked, and the documentation checks |

## Project status

The documentation foundation is complete: product vision, roadmap, architecture,
security, AI integration, decision records, and engineering guardrails are all
written and cross-linked, and `scripts/check-docs.sh` keeps them honest.

No application code has been written yet. Implementation begins at Phase 0,
which delivers the monorepo, Docker Compose, Prisma, JWT authentication, the
shared Zod package, and the GitHub Actions pipeline that enforces the gates
described above. Each phase becomes its own design spec and implementation plan
before any of it is built. The phase-by-phase plan, with acceptance criteria,
is in the [Product Roadmap](docs/product/roadmap.md).

## Running locally

TBD — pending Phase 0 scaffolding.

## License

Released under the MIT License. See [LICENSE](LICENSE) for the full text.
