# ADR-0005: pnpm workspaces as monorepo tooling

- **Status:** Accepted
- **Date:** 2026-08-16
- **Deciders:** Caio Lima

## Context

The frontend, the backend, and the shared packages change together. A field
added to a Zod schema in the shared package is meaningless until the API accepts
it and the web application sends it, so the three move as one unit and must stay
version-locked. Splitting them across repositories would mean publishing the
shared package, bumping a dependency, and opening a second pull request for what
is conceptually one change — coordination overhead a solo developer pays on
every single feature.

That argues for a monorepo, and the monorepo itself was never in question. What
was in question is the tooling layered on top of it. This ADR was originally
recorded as `Proposed`, naming Turborepo as a leaning rather than a decision,
with two open questions attached. Both have now been answered.

The first question asked whether Nx's enforceable module boundaries justified
its configuration weight, given that ADR-0001 accepts a modular monolith on the
promise that boundaries hold. They do not, because the enforcement Nx offers is
aimed at the wrong target. `@nx/enforce-module-boundaries` constrains which
*package* may import which *package*. The boundary ADR-0001 actually worries
about is `domain/` importing from `infrastructure/` — directories inside a
single NestJS application, not separate packages. Nx would only cover that if
each DDD layer were promoted to its own package, which is a structural
commitment the architecture does not otherwise call for. The same guarantee is
available from an ESLint rule (`import/no-restricted-paths`, or
`eslint-plugin-boundaries`) in roughly fifteen lines of configuration, with no
monorepo tooling involved at all. Mechanical boundary enforcement is therefore
separable from the choice of task runner, and it does not argue for either one.

The second question asked whether caching is worth any tooling at all at this
size. It is not, and the reason is narrower than it first appears. `pnpm -r run
build` already executes in topological order: pnpm reads the dependency graph
from the workspace's `package.json` files and builds the shared package before
the applications that consume it. Dependency ordering and parallel execution —
the capabilities most often cited as the reason to add a task runner — are
already present. The one capability a runner adds on top is content-based
incremental caching, and across two applications and three packages there is not
enough build time for a cache to reclaim.

There is also a working-context argument that carries real weight. The same
developer maintains a substantially larger system at work — twelve Node
services plus a frontend — on plain pnpm workspaces driven by scripts in the
root `package.json`. If that arrangement holds at twelve services, it is not
going to be the constraint at five packages. Choosing the same tooling here
means that operational knowledge transfers in both directions rather than being
split across two different mental models.

That evidence is strong but not unlimited, and the limit is worth recording: a
`pnpm run dev` that orchestrates services in watch mode is not the same workload
as a CI pipeline building in dependency order on every push. The precedent shows
that plain workspaces are viable at scale; what actually settles this decision
is the size of this repository.

## Decision

We will use pnpm workspaces as the monorepo tooling, with tasks invoked through
`pnpm -r` and scripts declared in the root `package.json`. No task runner is
adopted in Phase 0.

### Revisit trigger

This decision is revisited when measurement — not intuition — says the build has
outgrown it. Either of the following is sufficient:

- a local `pnpm -r build` exceeding roughly 90 seconds, or
- a CI run exceeding roughly 3 minutes on the
  `lint → test:coverage(≥70%) → build → scan → deploy` pipeline.

At that point Turborepo is adopted by adding a `turbo.json` and replacing
`pnpm -r <task>` with `turbo <task>` in the CI job definitions. The cost of that
change is bounded and known, which is what makes deferring it safe rather than
merely optimistic.

## Consequences

### Positive

- Nothing new to learn, configure, or keep up to date. The workspace is
  described by `pnpm-workspace.yaml` and a set of ordinary npm scripts, both of
  which any JavaScript developer can read without knowing this project.
- Build knowledge lives in exactly one place. A task runner is a second home for
  it alongside the package scripts, and the two can drift; with no runner there
  is nothing to drift from.
- The tooling matches what the maintainer already operates day to day, so
  practice here compounds with practice there instead of competing with it.
- No hosted dependency. Turborepo's remote caching would introduce an external
  service and an account into a project that otherwise runs entirely on local
  and GitHub-hosted infrastructure.
- pnpm's strict, non-hoisted `node_modules` means a package can only import what
  it actually declares, which removes a class of phantom-dependency bugs that
  npm's flat layout permits. This is a modest benefit rather than a reason to
  choose, but it points the same way.

### Negative

- No incremental caching. Every CI run rebuilds every package, including the
  ones that did not change. At the current size this costs seconds; it is a real
  cost that grows with the repository, and the revisit trigger exists precisely
  because it will not stay negligible forever.
- Parallelism is coarser. `pnpm -r` parallelizes across the dependency graph,
  but without the fine-grained task-level scheduling a dedicated runner applies.
- Adopting a runner later means rewriting the CI job definitions in that
  runner's vocabulary. The rewrite is small and its shape is described above,
  but it is not free, and it is paid at a moment when the pipeline is presumably
  already under pressure.

### Neutral

- Module-boundary enforcement is now an explicitly separate concern, delivered
  through ESLint rather than through monorepo tooling. It belongs in the Phase 0
  scaffolding work and is tracked there, not here.
- The repository layout, the package boundaries, and the scripts are unchanged
  by this decision. They would survive the later adoption of any runner, which
  is what keeps the revisit trigger cheap to act on.

## Alternatives Considered

### Turborepo

A task graph with content-based caching, minimal configuration, and — unlike Nx
— a design that sits beside plain workspaces rather than replacing them. It
remains the most likely answer if this decision is revisited, and the revisit
trigger names it by name.

It was not chosen now because its one distinguishing capability over plain pnpm
is the incremental cache, and at two applications and three packages there is
not enough build time for that cache to pay for itself. Adopting it today would
mean carrying configuration whose benefit cannot yet be measured, which is the
same speculative-tooling instinct the project's guardrails exist to resist.

### Nx

Richer generators, dependency-graph visualization, and enforceable module
boundaries between packages. Rejected on two counts. Its boundary enforcement
targets package-to-package imports rather than the layer-to-layer imports inside
the NestJS application that ADR-0001 actually depends on, so it does not buy the
guarantee it appears to buy. And it is invasive: Nx wants to own the project
graph, and its executors and generators replace parts of the plain npm script
surface rather than sitting beside them. For one developer, that is a meaningful
amount of tooling to learn and maintain before the first feature ships, in
exchange for capabilities this repository has no demonstrated need for.

### Multiple repositories

Rejected for the reason given in the Context: the shared Zod package, the API,
and the web application change as one unit, and splitting them would turn a
single logical change into a publish, a version bump, and a second pull request.
