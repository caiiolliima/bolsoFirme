# Architecture Overview

- **Date:** 2026-08-13

## Purpose

This document describes the shape of the Bolso Firme system: the technologies it
is built from, the architectural style that holds them together, the internal
layering of the backend, and the way the repository is organized. It is the
first document to read before touching code, because it establishes the
vocabulary — modular monolith, `domain`, `application`, `infrastructure`,
`interface`, shared package — that every other document reuses. What it
deliberately does not contain is the reasoning behind any individual choice.
Each decision, the alternatives that were weighed against it, and the costs it
accepts are recorded in an Architecture Decision Record under `../adr/`, and
this document links to them rather than restating them. When the two disagree,
the ADR is the authority: this overview describes the current design, while the
ADRs explain why it looks that way and under what evidence it would change.
Everything described here is the target design; it is implemented phase by phase
and none of it exists as running code yet.

## Stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | [Next.js 14+ (App Router)](../adr/0002-nextjs-nestjs-typescript-stack.md) + React + TypeScript | SSR/SSG, file-based routing, mature ecosystem, straightforward deployment |
| Backend | [NestJS 10+](../adr/0002-nextjs-nestjs-typescript-stack.md) + TypeScript | Modular architecture, native DI, pipes and guards, testable, scalable |
| Database | [PostgreSQL 16 + Prisma ORM](../adr/0003-postgresql-prisma-orm.md) | Transactions, JSONB, indexing, `pgvector` extension for future AI work, type-safe access |
| Validation | [Zod (shared package)](../adr/0004-zod-shared-validation-contract.md) | Single contract across frontend and backend, runtime validation plus type inference |
| Local infra | Docker Compose + [Turborepo](../adr/0005-turborepo-monorepo-tooling.md) | Reproducible environment, incremental caching, parallel builds |
| Cloud infra | AWS or Azure (future) | Containers identical to local, scale on demand |

Two entries carry a caveat worth stating in prose. Turborepo is the current
leaning rather than a settled choice — ADR-0005 is `Proposed`, not `Accepted`,
and the monorepo task runner is evaluated before Phase 0 scaffolding begins. The
cloud row is intentionally undecided: the deployment target is containers, and
because the local environment already runs the same containers under Docker
Compose, picking a provider is a late decision rather than an early one.

The single unifying property of the table is that TypeScript runs at every layer
of it. A Zod schema written once in the shared package validates a form in the
browser, validates the request body at the controller, and validates an LLM
response inside the infrastructure layer, with the TypeScript type inferred from
that same schema rather than declared alongside it. That is the reason the stack
looks the way it does, and it is recorded in
[ADR-0004](../adr/0004-zod-shared-validation-contract.md).

## Architectural style

The backend is a **modular monolith**: one deployable NestJS application, with
strict internal module boundaries and DDD layering inside it. Modules such as
transactions, budgets, goals, and portfolio are separated as thoroughly as they
would be in a distributed system — each owns its entities, its use cases, and
its repository interfaces, and reaches other modules only through their public
surface — but they are compiled and deployed as one artifact and share one
PostgreSQL database.

That choice buys the things a solo developer needs most at this stage. The whole
system runs locally under Docker Compose, so reproducing a bug means running
what the user runs. A release is a single build and a single rollback, with no
version matrix between services. Most importantly, while the domain model is
still moving, relocating a concept from one module to another is a
compiler-checked refactor rather than a contract negotiation between two
independently deployed services. And because a financial operation routinely
touches several modules at once — importing a statement creates transactions,
which consume budget, which may advance a goal — a single ACID database
transaction covers the whole operation instead of a saga with compensating
actions.

It also has a real cost, and the cost is stated plainly rather than argued away:
the application scales as a unit, a fault in one module degrades all of them,
and module boundaries are enforced by discipline and code review rather than by
the network, so they can erode one convenient import at a time.

The decision is not permanent, and the conditions for revisiting it are written
down so the conversation happens on evidence instead of instinct. **Service
extraction is reconsidered when p95 latency exceeds 2s, when deploys are blocked
by unrelated modules, or when one module genuinely needs to scale
independently.** Until at least one of those three conditions is observed and
recorded, the answer to "should this become a service" is no. The DDD layering
described in the next section is what keeps that escape hatch usable: a module
whose rules live in `domain` behind repository interfaces can be lifted into its
own deployable by swapping the `infrastructure` implementations, while a module
that queries the database straight from a controller cannot.

Full reasoning, rejected alternatives, and the accepted trade-offs are in
[ADR-0001: Modular monolith over microservices](../adr/0001-modular-monolith-over-microservices.md).

## Backend layers

Every backend module is organized into the same four layers:

| Layer | Responsibility | Example |
|---|---|---|
| `domain/` | Pure rules, entities, value objects, repository interfaces | `Transaction.value > 0`, `Budget.isWithinLimit()` |
| `application/` | Use cases, DTOs, rule orchestration | `CreateTransactionUseCase`, `CalculateBudgetProjection` |
| `infrastructure/` | Database (Prisma), parsers (OFX/CSV), LLM clients, email, queues | `PrismaTransactionRepo`, `OpenAIProvider`, `BullMQQueue` |
| `interface/` | Controllers, guards, pipes, OpenAPI/Swagger | `TransactionController`, `JwtAuthGuard` |

The layers are held together by one rule, and the rule is what makes the table
more than a folder convention: **dependencies point inward**. The `interface`
layer may depend on `application`; `application` may depend on `domain`;
`infrastructure` may depend on `domain` in order to implement what it declares.
Nothing points the other way. In particular, `domain` imports nothing from the
other three layers — no Prisma client, no NestJS decorator, no HTTP type, no LLM
SDK. A financial rule is expressible as a function of entities and value
objects, and if writing one appears to require a database handle or a request
object, that is a signal the rule has been placed in the wrong layer.

The mechanism that makes the inward rule practical is dependency inversion at
the persistence boundary: **repository interfaces are declared in `domain` but
implemented in `infrastructure`**. `TransactionRepository` is a `domain`
interface phrased in domain terms; `PrismaTransactionRepo` is the
`infrastructure` class that satisfies it, and NestJS dependency injection binds
one to the other at module composition time. The practical payoffs are
immediate: use cases in `application` are unit-testable against an in-memory
implementation with no database running, the ORM stays a replaceable detail
rather than a structural commitment, and the raw SQL escape hatches that Prisma
occasionally requires stay quarantined inside `infrastructure` where they are
covered by integration tests. The same inversion applies to every external
dependency, LLM providers included, which is what allows a model client to be
swapped for a deterministic fallback without any change reaching the domain.

## Repository layout

The project is a single monorepo holding both applications and the packages they
share:

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

- **`apps/web/`** — the Next.js 14+ frontend, using the App Router. It renders
  the dashboard, owns client state and charting, and consumes the API over HTTP.
  It contains no financial rules; a calculation that appears here is a
  calculation that belongs in the backend `domain` layer.
- **`apps/api/`** — the NestJS 10+ backend, the single deployable described in
  the architectural style section. Its internal structure is the four-layer
  breakdown above, repeated per module.
- **`packages/shared/`** — the cross-boundary contract: Zod schemas, the
  TypeScript types inferred from them, shared utilities, and constants. This is
  the package that makes one definition serve both applications, and it is the
  reason a field cannot be validated one way on the client and another way on
  the server.
- **`packages/prompts/`** — versioned LLM prompts as files rather than string
  literals scattered through service code, each carrying a semantic version
  (`v1.0`, `v1.1`, and so on). Keeping prompts here makes a prompt change a
  reviewable diff in a pull request, gated by a regression test, exactly as a
  code change is.
- **`packages/config/`** — the shared toolchain: ESLint, Prettier, TSConfig, and
  the Jest/Vitest setup. Centralizing it means lint and compiler rules cannot
  drift between the two applications, which is what keeps a single CI pipeline
  meaningful across the workspace.
- **`docker-compose.yml`** — the local environment, bringing up the API and
  PostgreSQL 16 so the entire system runs on one command and the containers match
  what is eventually deployed.
- **`turbo.json`** — the task graph and cache configuration for Turborepo, which
  is what allows unchanged packages to skip rebuilds. It is listed here because
  it is where the current proposal points; the runner itself is still open in
  ADR-0005.

This layout describes the target structure. It lands in Phase 0, together with
the pipeline that builds it.

## Related decisions

- [ADR-0001: Modular monolith over microservices](../adr/0001-modular-monolith-over-microservices.md) — one deployable NestJS application with strict internal boundaries, plus the explicit criteria (latency above 2s, blocked deploys, or a genuine need for independent scaling) that would justify splitting it.
- [ADR-0002: Next.js, NestJS, and TypeScript stack](../adr/0002-nextjs-nestjs-typescript-stack.md) — TypeScript everywhere, Next.js 14+ with the App Router on the frontend, NestJS 10+ on the backend, and why Remix, Express, and a non-TypeScript backend were rejected.
- [ADR-0003: PostgreSQL and Prisma ORM](../adr/0003-postgresql-prisma-orm.md) — PostgreSQL 16 for ACID guarantees, JSONB, and future `pgvector` work, with Prisma as the type-safe data-access layer.
- [ADR-0004: Zod as the shared validation contract](../adr/0004-zod-shared-validation-contract.md) — every cross-boundary shape defined once as a Zod schema in the shared package, with TypeScript types inferred from it rather than declared separately.
- [ADR-0005: Turborepo as monorepo tooling](../adr/0005-turborepo-monorepo-tooling.md) — the monorepo task runner. Still `Proposed` rather than `Accepted`; Nx and plain workspaces remain live options pending an evaluation before Phase 0.
- [ADR-0006: LLM guardrails and deterministic fallback](../adr/0006-llm-guardrails-deterministic-fallback.md) — every model call treated as an untrusted input source: versioned prompts, Zod-validated output, bounded temperature, logged cost, and a deterministic path that runs whenever the model fails.
- [ADR template](../adr/template.md) — the section layout every decision record follows.
