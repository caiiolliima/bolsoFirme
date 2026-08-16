# CLAUDE.md

Operational context for development sessions on Bolso Firme. Read this before
touching anything in the repository; it states what the project is, how it is
built, and the rules that hold regardless of which task is in front of you.

## Project

Bolso Firme is a personal finance platform that turns scattered spending data
into a single answer to the question "am I on track this month". It combines a
macro-to-micro dashboard, per-category budgeting, visible goals, and a
consolidated investment portfolio in one product instead of three, and it uses
LLMs where judgement genuinely helps — categorizing an unseen merchant string,
narrating a savings scenario — while keeping every number deterministic. The
full problem statement, the differentiator, and the scope boundary are in
[docs/product/vision.md](docs/product/vision.md).

## Engineering philosophy

This is a portfolio project where *how* it is built is part of the deliverable,
so it is built with production rigor from day one rather than rewritten into
rigor later. Every feature ships with tests, schema validation at each trust
boundary, observability, and a deterministic path that runs when the clever path
fails. LLMs are controlled copilots, never blind generators: their output is
validated before it is used, and generated code that cannot be explained line by
line does not get merged. Zero vibe coding is a rule with teeth, not a slogan —
the full contract, including the six rules, the definition of done, and the
quality gates, is in
[docs/engineering/guardrails.md](docs/engineering/guardrails.md).

## Tech stack

| Layer | Technology | ADR |
|---|---|---|
| Frontend | Next.js 14+ (App Router) + React + TypeScript | [ADR-0002](docs/adr/0002-nextjs-nestjs-typescript-stack.md) |
| Backend | NestJS 10+ + TypeScript | [ADR-0002](docs/adr/0002-nextjs-nestjs-typescript-stack.md) |
| Database | PostgreSQL 16 + Prisma ORM | [ADR-0003](docs/adr/0003-postgresql-prisma-orm.md) |
| Validation | Zod (shared package) | [ADR-0004](docs/adr/0004-zod-shared-validation-contract.md) |
| Local infra | Docker Compose + pnpm workspaces | [ADR-0005](docs/adr/0005-pnpm-workspaces-monorepo-tooling.md) |
| AI/LLM | Versioned prompts, Zod-validated output, deterministic fallback | [ADR-0006](docs/adr/0006-llm-guardrails-deterministic-fallback.md) |

TypeScript runs at every layer, which is the point of the table: a Zod schema
written once validates a browser form, a request body, and an LLM response, with
the TypeScript type inferred from that schema rather than declared beside it.

## Architecture

The backend is a **modular monolith** — one deployable NestJS application whose
modules (transactions, budgets, goals, portfolio) keep strict internal
boundaries and share a single PostgreSQL database. Every module is organized
into the same four DDD layers: `domain/` for pure rules, entities, value
objects, and repository interfaces; `application/` for use cases, DTOs, and rule
orchestration; `infrastructure/` for Prisma, OFX/CSV parsers, LLM clients, and
queues; and `interface/` for controllers, guards, pipes, and OpenAPI. The rule
that makes those layers more than folders is that **dependencies point inward**:
`domain` imports nothing from the other three, and repository interfaces are
declared in `domain` but implemented in `infrastructure`. Service extraction is
reconsidered only when p95 latency exceeds 2s, when deploys are blocked by
unrelated modules, or when one module genuinely needs to scale independently.
Full detail is in
[docs/architecture/overview.md](docs/architecture/overview.md).

## Repository structure

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
└── pnpm-workspace.yaml
```

This describes the target structure, not the current tree. It lands in Phase 0
together with the pipeline that builds it, so a session that needs one of these
directories today is a session that is creating it.

## Non-negotiables

- No merge without `test → lint → schema validation → manual code review`
- Prompts live in `/packages/prompts/` and are versioned; changes need a PR and a regression test
- Every LLM call has a deterministic fallback and logs `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status`
- Temperature `≤ 0.3` on financial analysis, `≤ 0.2` on goal projection
- No hardcoded secrets, ever — `.env` locally, a secrets manager in production
- Cross-boundary shapes are Zod schemas in the shared package; types are inferred from them
- Code that cannot be explained does not get merged

## Commands

TBD — pending Phase 0 scaffolding.

## Documentation map

**Product**

- [docs/product/vision.md](docs/product/vision.md) — the problem, the solution, the differentiator, and the engineering objective behind the project.
- [docs/product/roadmap.md](docs/product/roadmap.md) — Phases 0 through 7+ with technical deliverables and acceptance criteria, plus planning estimates.

**Architecture**

- [docs/architecture/overview.md](docs/architecture/overview.md) — stack, modular monolith, the four DDD layers, and the monorepo layout.
- [docs/architecture/security.md](docs/architecture/security.md) — authentication and authorization, encryption, secrets handling, STRIDE threat modeling, and audit logging.
- [docs/architecture/ai-integration.md](docs/architecture/ai-integration.md) — LLM features in the product, LLM discipline in development, and the full call lifecycle from prompt load to fallback.

**Decisions**

- [docs/adr/0001-modular-monolith-over-microservices.md](docs/adr/0001-modular-monolith-over-microservices.md) — one deployable, with the explicit criteria that would justify splitting it.
- [docs/adr/0002-nextjs-nestjs-typescript-stack.md](docs/adr/0002-nextjs-nestjs-typescript-stack.md) — TypeScript everywhere, Next.js 14+ on the frontend, NestJS 10+ on the backend.
- [docs/adr/0003-postgresql-prisma-orm.md](docs/adr/0003-postgresql-prisma-orm.md) — PostgreSQL 16 for ACID guarantees, JSONB, and future `pgvector` work, with Prisma as the data-access layer.
- [docs/adr/0004-zod-shared-validation-contract.md](docs/adr/0004-zod-shared-validation-contract.md) — one validation contract across frontend, backend, and the LLM boundary.
- [docs/adr/0005-pnpm-workspaces-monorepo-tooling.md](docs/adr/0005-pnpm-workspaces-monorepo-tooling.md) — pnpm workspaces and root scripts, with no task runner; includes the measured trigger for adopting Turborepo later.
- [docs/adr/0006-llm-guardrails-deterministic-fallback.md](docs/adr/0006-llm-guardrails-deterministic-fallback.md) — how model output is constrained in a financial domain, and what happens when a call fails.
- [docs/adr/template.md](docs/adr/template.md) — the section layout every decision record follows.

**Engineering**

- [docs/engineering/guardrails.md](docs/engineering/guardrails.md) — the six rules, the definition of done, the CI/CD gates, the metrics that must exist before a feature ships, and the documentation check script.

## Working agreements

Documentation, code comments, and commit messages are written in English, so
that anyone opening the public repository can read all of it; conversation with
the maintainer may happen in Portuguese, which changes nothing about what gets
committed. Commits follow Conventional Commits, with a type prefix such as
`docs:` or `feat:` and an English body. Each roadmap phase gets its own design
spec and implementation plan before implementation starts, and no phase is
started by improvising from the roadmap table alone — the roadmap is the map,
not the execution plan.
