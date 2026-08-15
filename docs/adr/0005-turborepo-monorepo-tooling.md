# ADR-0005: Turborepo as monorepo tooling

- **Status:** Proposed
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

The frontend, the backend, and the shared packages change together. A field
added to a Zod schema in the shared package is meaningless until the API accepts
it and the web application sends it, so the three move as one unit and must stay
version-locked. Splitting them across repositories would mean publishing the
shared package, bumping a dependency, and opening a second pull request for what
is conceptually one change — coordination overhead a solo developer pays on
every single feature.

That argues for a monorepo, and the monorepo itself is not in question. What is
in question is the tooling layered on top of it. Workspaces alone are enough to
link packages; a task runner adds an orchestrated task graph, incremental
caching, and parallel execution. That layer is expensive to reverse once it
exists: CI job definitions, cache configuration, and the pipeline steps in
`lint → test:coverage(≥70%) → build → scan → deploy` all end up phrased in
the runner's vocabulary, and swapping runners later means rewriting them.

There is also a timing problem. The decision would be made now, before Phase 0
has produced any packages, any CI, or any build times worth caching. The
evidence that would settle it — how long a cold build actually takes, how often
CI rebuilds unchanged packages, whether module boundaries hold under review
alone — does not exist yet.

## Decision

We propose Turborepo as the monorepo task runner, pending a dedicated evaluation
before Phase 0 scaffolding begins.

This ADR records the current leaning and the reasoning behind it so the
evaluation starts from a written position rather than from scratch. It is not a
commitment, and no Phase 0 work should treat it as settled.

## Consequences

### Positive

- A task graph with content-based caching, so unchanged packages skip rebuilds.
  Once CI runs on every push, the difference between rebuilding one package and
  rebuilding the whole workspace is the difference between a fast feedback loop
  and one nobody waits for.
- Minimal configuration. The pipeline is a short declaration of task
  dependencies rather than a project model that has to be maintained.
- It works with plain npm or pnpm workspaces rather than replacing them, so the
  underlying package layout stays standard and the runner remains a layer that
  can be peeled off.

### Negative

- Turborepo handles task orchestration but not code generation or
  dependency-graph enforcement, so module-boundary rules stay a matter of review
  discipline. That matters more here than usual, because ADR-0001 accepts a
  modular monolith specifically on the promise that boundaries hold.
- Remote caching pulls in a hosted dependency if enabled, which adds an external
  service and an account to a project that otherwise runs entirely on local and
  GitHub-hosted infrastructure.
- Any task runner is a second place where build knowledge lives, alongside the
  package scripts themselves, and the two can drift.

### Neutral

- The choice is largely reversible at the level of the repository layout:
  workspaces, package boundaries, and scripts survive a change of runner. What
  does not survive is the CI configuration and cache setup built on top, which
  is why the evaluation belongs before Phase 0 rather than after it.

## Alternatives Considered

### Nx

Richer generators, dependency-graph visualization, and enforceable module
boundaries — which is a genuine draw given ADR-0001's reliance on boundary
discipline. A lint rule that fails the build when `domain` imports from
`infrastructure` is a stronger guarantee than a reviewer noticing it. The cost
is heavier configuration and a more invasive workspace model: Nx wants to own
the project graph, and its executors and generators replace parts of the plain
npm script surface rather than sitting beside them. For one developer, that is a
meaningful amount of tooling to learn and maintain before the first feature
ships.

### Plain pnpm workspaces with no task runner

Zero added tooling and the fewest moving parts: packages link through the
workspace protocol and every task is a plain script invoked directly. Nothing
new to learn, nothing new to configure, nothing new to break. It loses
incremental caching, which matters once CI runs on every push and the same
unchanged packages are rebuilt on each one.

## Open Questions

- Does Nx's enforceable module-boundary linting justify its configuration
  weight, given that ADR-0001 leans on boundaries holding? If the boundary rules
  are the main risk in the architecture, buying mechanical enforcement may be
  worth the heavier tooling.
- Is caching worth any tooling at all before CI exists? A workspace with three
  packages and no pipeline may not have build times that a cache can meaningfully
  improve, in which case the plain-workspaces option is the honest answer until
  measurements say otherwise.

This decision is revisited in a dedicated discussion and the status is updated
to `Accepted` or superseded then.
