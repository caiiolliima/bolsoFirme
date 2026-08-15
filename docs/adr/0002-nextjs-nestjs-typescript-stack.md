# ADR-0002: TypeScript everywhere with Next.js on the frontend and NestJS on the backend

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

Bolso Firme is built and maintained by a solo developer. Every additional
language in the stack multiplies the cost of context switching, of keeping two
sets of idioms in working memory, and of maintaining two toolchains for
linting, testing, formatting, and building. A single developer benefits
disproportionately from one language across the whole stack, because the time
saved is not shared with a team that could have absorbed the overhead.

The product is a data-heavy dashboard. The first screen a user sees aggregates
transactions, budget consumption, goal progress, and portfolio position. First
paint on that screen cannot wait for a client-side bundle to boot, fetch, and
then render; the pages that carry aggregate data need to be rendered on the
server so that meaningful content arrives in the first response. The latency
target the product holds itself to from Phase 1 onward is p95 < 1s, which the
rendering strategy has to respect rather than fight.

The backend is planned as a modular monolith with DDD layering, where the
`application` layer must be exercisable in tests without a database, a network,
or an HTTP server. That requires real seams: dependency inversion at the
repository boundary, and a composition mechanism that can substitute a test
double for an infrastructure adapter without rewriting the use case. A backend
framework that offers no such primitive would force those seams to be
hand-rolled, and hand-rolled seams tend to be bypassed under time pressure.

## Decision

We will use TypeScript everywhere, Next.js 14+ with the App Router on the
frontend, and NestJS 10+ on the backend.

## Consequences

### Positive

- Types and Zod schemas cross the network boundary without translation. A shape
  defined once in the shared package is the same shape the client validates, the
  server validates, and the compiler checks on both sides.
- One toolchain covers lint, test, and build for the whole repository. There is
  a single formatter configuration, a single test runner idiom, and a single set
  of editor integrations to keep working.
- NestJS's native dependency injection makes the `application` layer testable
  without touching a database. Use cases receive repository interfaces through
  the constructor, so a unit test supplies an in-memory implementation and the
  use case never learns that Prisma exists.
- The ecosystem is large enough that most problems are already answered.
  Statement parsing, charting, authentication patterns, and job queues all have
  well-travelled TypeScript solutions, which matters when there is no second
  developer to split unknowns with.

### Negative

- NestJS's decorator-heavy style is opinionated and adds a learning curve.
  Modules, providers, injection tokens, and the resolution order between them are
  framework knowledge that does not transfer elsewhere, and misconfiguration
  tends to surface as an opaque runtime resolution error rather than a compile
  error.
- The App Router's server/client component split is a genuine source of subtle
  bugs. The boundary between a server component and a client component is easy to
  cross accidentally, and the failure modes are indirect: a value that cannot be
  serialized, a hook that runs where there is no interactivity, or a secret that
  travels further than intended.
- A single-language stack means a single-ecosystem risk. A breaking change in the
  TypeScript or Node.js release line, or a stall in one of the two frameworks,
  affects the frontend and the backend at the same time rather than only half of
  the system.

### Neutral

The two frameworks version independently, so the repository carries two upgrade
cadences even though it carries one language. Next.js and NestJS also disagree
on several conventions, notably module resolution and build output, which is why
the shared package must be consumable by both build pipelines rather than tuned
for either one.

## Alternatives Considered

### Remix or SvelteKit

Both are credible server-rendering frameworks, and SvelteKit in particular has a
smaller runtime and a simpler reactivity model than React. They were rejected
because the dashboard leans on the React charting ecosystem (Recharts), which has
no equivalent depth outside React, and because the React Native path planned for
Phase 7+ makes React knowledge reusable on mobile. Choosing a non-React framework
would trade a reusable skill and a mature charting library for a nicer
authoring experience on the web only.

### Express or Fastify

Both are faster to start with than NestJS and impose almost nothing on how the
application is structured. They were rejected because the dependency injection,
guard, pipe, and module primitives that NestJS provides would have to be
hand-rolled, and hand-rolled versions are where the DDD boundaries would erode
first. The boundaries in ADR-0001 are enforced by discipline rather than by the
network, so a framework that makes the correct structure the default path is
doing load-bearing work, not decorating.

### A non-TypeScript backend (Go, Python)

Go would give better runtime performance and simpler deployment artifacts, and
Python would give a shorter path to data and model tooling. Both were rejected
because a non-TypeScript backend would break the shared Zod contract described in
[ADR-0004](0004-zod-shared-validation-contract.md): the schema could no longer be
the single definition consumed by both sides, so the same shape would be declared
twice in two languages, and the two declarations would drift. It would also
double the toolchain for one developer, adding a second dependency manager, test
runner, linter, and build pipeline to maintain for the lifetime of the project.
