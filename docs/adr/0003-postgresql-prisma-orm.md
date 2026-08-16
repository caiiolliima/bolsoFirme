# ADR-0003: PostgreSQL 16 with Prisma ORM for persistence

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

The data this product stores is financial. A transaction, a budget consumption
figure, and a goal contribution are not independent rows that happen to sit near
each other; a single user action frequently writes several of them at once, and a
partially applied write leaves the user looking at numbers that do not add up.
Correctness under concurrent writes is therefore non-negotiable, and it has to be
guaranteed by the storage engine rather than reconstructed by application code
after the fact.

The read side is aggregate-shaped. Budgets are consumption over a period and a
category, goals are progress against a projected contribution curve, and the
dashboard is a set of rollups over the same transaction table sliced by time,
category, and account. These are grouping, filtering, and window queries over a
normalized set of rows, which is the workload relational engines are built for.

Phase 3 and later anticipate embedding-based features: similarity over merchant
descriptions to improve categorization, and retrieval over a user's own history
to ground generated insights. Introducing a dedicated vector database for that
would mean a second datastore to operate, back up, and keep consistent with the
primary one, for a workload that is small relative to the transaction table.

Finally, the developer is solo. A hand-written data-access layer means writing
and maintaining mapping code, migration tooling, and connection handling, none of
which is product work. The data layer needs to be something that can be
delegated to a well-maintained library without giving up type safety.

## Decision

We will use PostgreSQL 16 as the database and Prisma as the ORM.

## Consequences

### Positive

- ACID transactions for multi-row financial writes. Importing a statement,
  recording a transaction and its budget effect, or applying a contribution to a
  goal either lands completely or not at all, enforced by the engine.
- JSONB for parser output that has not earned a schema yet. Raw OFX and CSV
  records carry issuer-specific fields whose shape is not stable enough to model
  in columns; storing them as JSONB keeps them queryable and available for
  reprocessing without freezing a schema prematurely.
- The `pgvector` extension is available without a second datastore when AI
  features arrive. Embeddings live next to the rows they describe, in the same
  backup, the same transaction, and the same access-control boundary.
- Prisma generates types that flow into the same TypeScript codebase as the Zod
  schemas, so a query result and a validated payload are checked by the same
  compiler rather than being connected by convention.
- Migrations are versioned and reviewable. A schema change arrives as a file in a
  pull request, is applied the same way in every environment, and can be read
  later to explain how the schema reached its current shape.

### Negative

- Prisma's query builder does not express every SQL construct. Complex reports,
  particularly window functions and recursive aggregations, may need raw SQL and
  lose type safety at exactly the point where the query is hardest to reason
  about.
- Prisma adds a code-generation step to the build. The generated client must be
  regenerated whenever the schema changes, which is one more state that can be
  stale locally and one more step that has to be correct in continuous
  integration.
- The abstraction makes it easy to write N+1 queries without noticing. A relation
  accessed inside a loop reads like a property access and costs a round trip, and
  nothing in the type system flags it.

### Neutral

Raw SQL escape hatches are acceptable when they are isolated inside the
`infrastructure` layer and covered by tests. A repository implementation is
allowed to reach for raw SQL to serve a query the builder cannot express; what is
not allowed is raw SQL leaking upward, because the `domain` and `application`
layers depend on repository interfaces and must not learn which engine is behind
them.

## Alternatives Considered

### MongoDB

A document model would fit the raw imported statement records well and would
remove the migration step for shapes that are still moving. It was rejected
because multi-document transactions in a financial ledger are the default case,
not the exception: nearly every write touches a transaction plus its derived
budget and goal effects. A document model would push that guarantee into
application code, which means writing and testing rollback logic by hand for a
property the relational engine provides for free.

### TypeORM

TypeORM is the closest ORM to the NestJS conventions chosen in ADR-0002 and would
have integrated with the least friction. It was rejected because its Active
Record and Data Mapper duality means the same codebase can express persistence in
two different styles, and its weaker type inference means query results are often
typed more loosely than they actually are. Both make repository interfaces harder
to keep honest, and the honesty of those interfaces is what keeps the
`infrastructure` layer replaceable.

### Drizzle

Genuinely close. Drizzle stays nearer to SQL, has no code-generation step, and
gives sharper inference on complex queries, which addresses two of the three
negatives listed above. It was rejected on ecosystem maturity and migration
tooling at decision time: fewer answered edge cases and a less settled migration
story are a poor trade for a solo developer who cannot absorb tooling surprises.
This is the most likely ADR in the set to be revisited, and the trigger would be
Drizzle's migration tooling reaching parity rather than a problem with
PostgreSQL, which is not in question here.
