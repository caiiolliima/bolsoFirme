# ADR-0001: Modular monolith over microservices

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

Bolso Firme is built and maintained by a single developer. There is no team to
split ownership across, no on-call rotation, and no operations budget beyond
what one person can absorb alongside feature work.

The system has no production traffic yet. That means there is no measured
bottleneck, no observed hot path, and no evidence that any part of the domain
needs more resources than any other. Any decomposition drawn today would be
drawn from guesswork about where load will land, and guesses about service
boundaries are expensive to undo once each boundary is a network hop with its
own deployment pipeline.

The domain is unusually cohesive. Transactions, budgets, goals, and portfolio
all read and write the same person's financial data, and most meaningful
operations touch more than one of them: importing a statement creates
transactions, which consume budget, which may advance or endanger a goal.
These are not loosely related bounded contexts that happen to share a product;
they are facets of one account balance.

Because the data is financial, correctness under concurrent writes is not
negotiable. A single database transaction that records a transfer, updates the
affected budget, and recalculates goal progress is straightforward inside one
process. The same operation spread across services becomes a distributed
transaction requiring sagas, compensating actions, and idempotency keys.
Distributed transactions over financial data are expensive to get right, and
the failure mode of getting them wrong is silent data corruption in a ledger a
user trusts.

Finally, the domain model is still moving. Category rules, budget semantics,
and goal projection are all likely to change shape several times before Phase 2
ends. Boundaries drawn around a model that is still being discovered tend to be
drawn in the wrong place.

## Decision

We will build the backend as a modular monolith — one deployable NestJS
application with strict internal module boundaries and DDD layering — and
extract services only when measurements demand it.

The criteria for reconsidering that extraction are explicit, so the decision
can be revisited on evidence rather than on instinct. Service extraction is
reconsidered when p95 latency exceeds 2s, when deploys are blocked by unrelated
modules, or when one module genuinely needs to scale independently. Until at
least one of those three conditions is observed and recorded, the answer to
"should this become a service" is no.

## Consequences

### Positive

- **One deployment target.** A release is a single build, a single artifact,
  and a single rollback. There is no version matrix between services, no
  ordering constraint on deploys, and no partially deployed state to reason
  about during an incident.
- **The whole system runs locally.** Docker Compose brings up the API and
  PostgreSQL, and that is the entire system. Reproducing a bug means running
  the same thing a user runs, not stubbing out four collaborators.
- **Refactoring across boundaries stays cheap.** While the domain model is
  still moving, moving a concept from one module to another is a compiler-
  checked rename rather than an API version negotiation between two
  independently deployed services. This is the single largest benefit at the
  current stage.
- **ACID transactions remain available across the whole domain.** Any operation
  that spans transactions, budgets, and goals commits or rolls back as a unit,
  using the database guarantee rather than application-level compensation.

### Negative

- **The application scales as a unit.** If statement parsing needs more memory,
  every module gets more memory, including the ones that were fine. Resource
  allocation is coarse and therefore wasteful at the margin.
- **Failure is not isolated.** A memory leak, an unbounded loop, or a blocking
  call in one module degrades every other module in the same process. There is
  no bulkhead: the dashboard slows down because the importer misbehaved.
- **Boundaries are enforced by discipline, not by the network.** In a
  distributed system, an illegal call fails because there is no route to make
  it. Here, an illegal call is one import statement away and compiles fine.
  Boundaries can therefore erode silently, one convenient shortcut at a time,
  and only code review and lint rules stand in the way. This is the real cost
  of the decision and it must be paid continuously.

### Neutral

DDD layering (`domain` / `application` / `infrastructure` / `interface`) is
what makes later extraction feasible; it is a prerequisite of this decision,
not a separate style preference. A module whose rules live in `domain` with no
dependency on Prisma, HTTP, or any LLM client can be lifted into its own
deployable by replacing the `infrastructure` implementations behind interfaces
that already exist. A module that reaches directly into the database from a
controller cannot. The layering is not aesthetic; it is the escape hatch that
keeps the split criteria above actionable rather than theoretical.

## Alternatives Considered

### Microservices from day one

Decompose the domain into independently deployable services — transactions,
budgets, goals, portfolio — each with its own database and release cycle,
communicating over HTTP or a message broker.

Rejected because the operational surface costs more than a solo developer can
carry. Service discovery, distributed tracing, per-service CI/CD pipelines,
inter-service contract versioning, and network-partition handling are each a
real body of work, and together they are a full-time responsibility before a
single line of product code exists. Every one of those costs would be paid up
front, before a single metric justifies it, in exchange for scaling and
isolation properties the system has no evidence of needing.

The trade-off is deliberate: this decision accepts worse failure isolation and
coarser scaling today in exchange for spending the available engineering time
on the domain instead of on the platform. The split criteria in the Decision
section are what convert that from an evasion into a plan.

### Serverless functions per endpoint

Deploy each endpoint as an independently scaling function, with the database
behind a connection pooler and no long-lived application process.

Rejected on two counts. First, cold starts conflict directly with the p95 < 1s
target set for Phase 1: a cold invocation plus connection acquisition can
consume most of that budget before any domain logic runs, and the endpoints
most likely to go cold are the infrequent ones a returning user hits first.
Second, per-function state makes the shared domain model awkward to express.
The entities, value objects, and repository interfaces that the DDD layering
depends on want to live in one long-lived process with a warm dependency graph;
splitting them across functions either duplicates the model or reduces each
function to a thin remote call into a shared layer that is itself the monolith
this alternative was meant to avoid.
