# Handoff: Phase 0 — Foundation & CI/CD

Paste the block below into a fresh Claude Code session opened at
`/home/caiolima/Documentos/dev/bolsoFirme`. It assumes zero prior context.

---

````text
You are picking up work on Bolso Firme. You have no prior context — everything
you need is on disk or on GitHub.

## Goal

Execute GitHub issue #1: write the design spec and the implementation plan for
Phase 0 (Foundation & CI/CD). Phase 0 delivers the monorepo, Docker Compose,
Prisma, JWT authentication, the shared Zod package, and the GitHub Actions
pipeline. Its acceptance criteria are CI green, coverage `≥ 70%`, and an
`.env.example` with no secrets.

This issue is documentation, not code. It blocks the other seven Phase 0 issues,
because `CLAUDE.md` states that no roadmap phase is started by improvising from
the roadmap table alone.

## Read first

1. GitHub issue #1 — `gh issue view 1 --repo caiiolliima/bolsoFirme`. The scope
   and the "done when" checklist.
2. `CLAUDE.md` — operational context, non-negotiables, working agreements.
3. `docs/product/roadmap.md` — the Phase 0 row and its acceptance criteria.
4. `docs/architecture/overview.md` — the target monorepo layout and the four DDD
   layers this scaffolding must produce.
5. `docs/engineering/guardrails.md` — the definition of done and the CI pipeline
   order that Phase 0 has to implement.
6. `docs/architecture/security.md` — the authentication design, which issue #6
   implements and which is the hardest part of the phase.
7. `docs/adr/0005-pnpm-workspaces-monorepo-tooling.md` — settled one session ago;
   read it before proposing any build tooling.

## State on disk

- Branch: `feat/create-scope`. Working tree clean.
- Last commits:
  - `48f3eaf` chore: ignore .env files
  - `be12471` docs: settle ADR-0005 on pnpm workspaces
  - `0f90f9e` docs: add MIT license file
  - `40836c0` docs: normalize security heading style
  - `66e8931` docs: retire the Portuguese scope document and Qwen context
- `./scripts/check-docs.sh` exits `0` (`check-docs: clean`). Keep it that way;
  run it before every commit that touches a `.md` file.

**The branch is 12 commits ahead of `master` and 11 of them are unpushed.** There
is no pull request. `master` still holds the superseded documentation set
(`docs/task-fase-*.md`, `docs/tasks-overview.md`, `docs/bolso-firme-escopo.md`),
none of which exists on this branch. See "Open questions" — this needs a decision
before Phase 0 code starts.

## Tracking

Work lives on GitHub, not in conversation. Check it before recommending anything:

```bash
gh issue list --repo caiiolliima/bolsoFirme
gh project item-list 1 --owner caiiolliima --format json
```

Board: **Bolso Firme Roadmap** (project 1). Milestone `Phase 0: Foundation &
CI/CD` holds issues #1–#8. Issue #1 is `In progress`; the rest are `Backlog`.

| Issue | Title |
|---|---|
| #1 | Write the Phase 0 design spec and implementation plan |
| #2 | Scaffold the pnpm workspace |
| #3 | Docker Compose with PostgreSQL 16 and .env.example |
| #4 | Prisma schema and first migration |
| #5 | Shared Zod package |
| #6 | JWT authentication with refresh token rotation |
| #7 | ESLint boundary rule for the DDD layers |
| #8 | GitHub Actions CI pipeline |

Close issues with `Closes #N` in the commit body. The board's default workflows
move the card to Done on merge; do not move cards by hand.

## Done so far

The complete documentation foundation, verified by `scripts/check-docs.sh`:
six ADRs, architecture (overview, security, ai-integration), product (vision,
roadmap), engineering guardrails, `CLAUDE.md`, `README.md`, `LICENSE`. The
Portuguese scope document was migrated and deleted; the migration was audited
section by section against 37 concrete technical terms before deletion.

ADR-0005 was resolved from `Proposed` to `Accepted` in the last session, and the
GitHub tracking above was set up from scratch.

## Next

Follow the project's own process, in this order:

1. **Brainstorm** the Phase 0 design with the user (superpowers:brainstorming).
   This is architectural — new subsystems, nothing to read in the repo yet.
2. **Write the spec** to
   `docs/superpowers/specs/2026-08-16-phase-0-foundation-design.md`.
3. **Write the plan** (superpowers:writing-plans) to
   `docs/superpowers/plans/2026-08-16-phase-0-foundation.md`, with a task per
   issue #2–#8 so every issue traces to a plan task.
4. Commit, and close issue #1.

Do not scaffold anything, install dependencies, or write product code in this
session. Issue #1's deliverable is two documents.

## Decisions made, with reasoning

Do not reopen these without new evidence.

- **pnpm workspaces, no task runner** (ADR-0005, `Accepted`). Nx was rejected
  because `@nx/enforce-module-boundaries` constrains package-to-package imports,
  while the boundary ADR-0001 depends on is `domain/` not importing
  `infrastructure/` — directories inside one package. Turborepo was rejected
  because `pnpm -r` already builds in topological order, leaving incremental
  caching as its only real addition, which two apps and three packages cannot
  justify. The ADR records a measured revisit trigger: local build over ~90s or
  CI over ~3min.
- **Module-boundary enforcement is a separate concern**, delivered through an
  ESLint rule (`import/no-restricted-paths` or `eslint-plugin-boundaries`), not
  through monorepo tooling. This became issue #7.
- **GitHub Issues and Projects over JIRA.** Zero setup, native `Closes #N`
  linking, and the repository is public so the board is portfolio-visible.
- **Issues are written in English**, matching the repository's language rule,
  even though the conversation with the maintainer is in Portuguese.
- **ADR-0005 was rewritten in place rather than superseded by a new ADR.** It had
  never been in force — it said so itself — and it explicitly anticipated its own
  status being updated. The file was renamed from
  `0005-turborepo-monorepo-tooling.md`, and every link to it was updated.

## Constraints that must survive

- **Every committed file is written in English.** Documentation, code comments,
  and commit messages. Conversation with the maintainer happens in Portuguese;
  that changes nothing about what gets committed.
- `scripts/check-docs.sh` fails on the characters `ã`, `õ`, `ç` in any tracked
  `.md` outside `docs/superpowers/`. Writing Portuguese into a committed document
  breaks the build.
- Only two placeholders exist in the whole repository, each reading exactly
  `TBD — pending Phase 0 scaffolding.` on one line: the `CLAUDE.md` commands
  section and the `README.md` local-setup section. Issue #8 closes the first and
  issue #3 the second. Do not add a third.
- Commits follow Conventional Commits with English bodies.
- Verbatim values that must be copied exactly wherever they appear: coverage
  `≥ 70%` (Phase 2 raises its own bar to `≥ 80%`), CI order
  `lint → test:coverage(≥70%) → build → scan → deploy`, PR gate
  `test → lint → schema validation → manual code review`, temperature `≤ 0.3` for
  financial analysis and `≤ 0.2` for goal projection, and the five observability
  fields `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status`.

## Traps

- **`gh` lives at `~/.local/bin/gh`**, installed from the official tarball. It is
  not an apt package — `sudo` cannot prompt for a password through this harness,
  so do not suggest `sudo apt install gh`. Ask the user to run interactive
  commands with a `!` prefix.
- `gh auth refresh` requires `--hostname github.com` when run non-interactively.
- The token now carries `gist`, `project`, `read:org`, `repo`. Project board
  access needed the `project` scope added separately after the initial login.
- **`README.md` and `CLAUDE.md` sit at the repository root**, so their links take
  the form `docs/architecture/overview.md` with no `../` prefix. Every other
  document lives inside `docs/` and uses `../`. This was the single largest
  source of broken links in the previous session.
- The relative links inside GitHub issues #2–#8 resolve against the **default
  branch**, which is `master`. Since `master` does not yet contain
  `docs/adr/`, those links are broken on GitHub right now. Merging fixes them.
- `test.js` at the repository root was **deliberately preserved** across an
  earlier plan that called for deleting a file named `test.ts`. It held the
  maintainer's JavaScript study exercises, was untracked, and deleting it would
  have been unrecoverable. It has since been removed by the maintainer, who
  migrated it elsewhere. Mentioned so nobody re-derives the deletion as safe.

## Open questions

**Needs the user's decision:**

- **Does `feat/create-scope` merge into `master` before Phase 0 starts?** The
  recommendation is yes: the documentation foundation is complete and verified,
  the issue links are broken until it lands, and Phase 0 is new work that
  deserves its own branch off an updated `master`. The branch name no longer
  describes what it carries.

**For the Phase 0 spec to settle:**

- Node and pnpm version pinning, and how (`.nvmrc`, `packageManager`, `engines`).
- Whether `packages/config` ships ESLint, Prettier, and TSConfig as real
  workspace packages or stays as root-level configuration.
- Test runner: Jest or Vitest, and whether both applications share one.
- How `.env` is loaded across the workspace, and whether the API and the web
  application read separate files.
- Whether issue #6 (JWT with refresh rotation) is large enough to earn its own
  design spec rather than being a plan task. It is the phase's only one-way door.
````

---

## Why this shape

The handoff leads with state rather than history because the next session acts
before it reads far. The unpushed-branch fact is stated twice — once in state,
once as an open question — because it changes what "start Phase 0" means and is
the easiest thing to miss.

The "Decisions made" section exists because none of it survives in git. A cold
session reading only the ADR would see the outcome but not that Nx was rejected
for targeting the wrong granularity, and would be free to re-propose it.
