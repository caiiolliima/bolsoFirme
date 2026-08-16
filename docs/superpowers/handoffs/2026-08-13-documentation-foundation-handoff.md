# Handoff: Documentation Foundation — Wave-Based Parallel Execution

Paste the block below into a fresh Claude Code session opened at
`/home/caiolima/Documentos/dev/bolsoFirme`. It is self-contained: it assumes
zero prior context.

---

## The prompt

````text
You are orchestrating the execution of an approved implementation plan in this
repository. You have no prior context — everything you need is on disk.

## Read first

1. `docs/superpowers/plans/2026-08-13-documentation-foundation.md` — the plan.
   Read it completely, including the "Global Constraints" section, before
   dispatching anything.
2. `docs/superpowers/specs/2026-08-13-documentation-foundation-design.md` — the
   spec the plan implements. Skim it for intent.

This is documentation-only work. Do not scaffold the monorepo, install
dependencies, or write any product code. The stack described in the docs
(Next.js, NestJS, Prisma, Zod) is documented, not built.

## Two overrides to the plan

The plan was written for single-threaded execution. You are running it in
parallel waves, so two things change:

1. **Subagents never run git commands.** Each task in the plan ends with a
   "Commit" step — subagents skip it. Concurrent commits in one working tree
   race on `index.lock`, and one agent's commit would sweep another's
   half-written files into it. Subagents write files and report; **you** commit
   once per wave, after verifying.
2. **Verification runs per wave, not per task.** Run
   `./scripts/check-docs.sh` yourself after each wave's agents have all
   returned. Individual agents do not run it — mid-wave the tree is
   legitimately inconsistent.

Everything else in the plan — file paths, content requirements, exact tables,
verbatim values — applies unchanged.

## Constraints that must survive delegation

Repeat these in every agent prompt; a subagent that has not read the plan's
Global Constraints will violate them silently.

- Every file is written in **English**. No Portuguese prose anywhere.
- Date in all documents and ADRs: `2026-08-13`. Decider: `Caio Lima`.
- **ADR-0005 has status `Proposed`, not `Accepted`, and keeps its
  `Open Questions` section.** This is deliberate — the monorepo tooling choice
  is still open. An agent that "fixes" it to `Accepted` has broken the task.
- The only two permitted placeholders in the whole set are the `CLAUDE.md`
  commands section and the `README.md` local-setup section. Each must read
  exactly `TBD — pending Phase 0 scaffolding.` on a single line — the check
  script only tolerates a `TBD` when `pending Phase 0` is on the same line.
- Copy the plan's verbatim technical values exactly: coverage `≥ 70%`, pipeline
  `lint → test:coverage(≥70%) → build → scan → deploy`, PR gate
  `test → lint → schema validation → manual code review`, temperature `≤ 0.3`
  (`≤ 0.2` for goal projection), the five observability fields, the split
  criteria, and the latency targets.
- Tables reproduced in the plan are data, not suggestions. Copy them as written.

## Wave plan

Dependencies are link-resolution dependencies: a document can be written before
its link targets exist, but the set must be consistent when the wave closes.

### Wave 0 — sequential, do this yourself

Plan Task 1 plus the template half of Task 2. Both are fully written out in the
plan; copying them is faster than delegating.

- Create `scripts/check-docs.sh` exactly as Task 1 Step 1 specifies, then
  `chmod +x scripts/check-docs.sh`.
- Create `docs/adr/template.md` exactly as Task 2 Step 1 specifies. Pulling it
  forward here means the three Wave 1 agents all start from a format that
  already exists on disk rather than three independent readings of it.
- Run `./scripts/check-docs.sh; echo "exit=$?"`.
  **Expected: exit `1`, reporting ~43 Portuguese lines in
  `docs/bolso-firme-escopo.md` and nothing else.** That file is the
  untranslated source document, deleted in Wave 4. This failure is the proof
  the checker works; if it exits `0` instead, the script is not matching files
  and must be fixed before going further.
- Commit: `docs: add documentation check script and ADR template`

**From Wave 1 through Wave 3, Portuguese hits in `docs/bolso-firme-escopo.md`
are the only acceptable finding.** Any placeholder, any Portuguese in another
file, or any broken link not named below is a real failure — fix it before
committing that wave.

### Wave 1 — 3 agents in parallel

All three write ADRs against the template from Wave 0.

| Agent | Writes | Plan section |
|---|---|---|
| A | `docs/adr/0001-modular-monolith-over-microservices.md` | Task 2, Step 2 |
| B | `docs/adr/0002-nextjs-nestjs-typescript-stack.md`, `docs/adr/0003-postgresql-prisma-orm.md` | Task 3, Steps 1–2 |
| C | `docs/adr/0004-zod-shared-validation-contract.md`, `docs/adr/0005-turborepo-monorepo-tooling.md`, `docs/adr/0006-llm-guardrails-deterministic-fallback.md` | Task 4, Steps 1–3 |

After all three return, run the checker. Expected: baseline only — no broken
links, because ADR-0002's forward reference to ADR-0004 is satisfied within
this same wave.

Commit: `docs: add architecture decision records`

### Wave 2 — 5 agents in parallel

Every ADR now exists, so all ADR links resolve.

| Agent | Writes | Plan section |
|---|---|---|
| D | `docs/architecture/overview.md` | Task 5, Step 1 |
| E | `docs/architecture/security.md` | Task 6, Step 1 |
| F | `docs/architecture/ai-integration.md` | Task 7, Step 1 |
| G | `docs/product/vision.md`, `docs/product/roadmap.md` | Task 8, Steps 1–2 |
| H | `docs/engineering/guardrails.md` | Task 9, Step 1 |

These five cross-link heavily — security → roadmap, ai-integration →
guardrails, vision → guardrails, guardrails → roadmap and ai-integration — and
every one of those targets is created inside this wave. That is why
verification is deferred to the end of the wave.

Two documents share content that must agree: `guardrails.md` and
`ai-integration.md` both carry the five LLM observability fields, and
`guardrails.md` and `overview.md` both restate pipeline values. Both agents
copy from the plan's verbatim tables, so they agree by construction — but check
this specifically when the wave closes.

After all five return, run the checker. **Expected: baseline only, and now with
no broken-link block at all.** This is the first wave where the documentation
set is internally complete.

Commit: `docs: add architecture, product, and engineering documentation`

### Wave 3 — 2 agents in parallel

| Agent | Writes | Plan section |
|---|---|---|
| I | `CLAUDE.md` | Task 10, Step 1 |
| J | `README.md` | Task 10, Step 2 |

Warn both: these two files sit at the repository root, so links take the form
`docs/architecture/overview.md` with **no** `../` prefix. Every other document
written so far lives inside `docs/` and uses `../`. This is the single most
likely source of broken links in the whole plan.

After both return, run the checker. Expected: baseline only, and both `TBD`
markers accepted. If a placeholder finding appears, the `TBD` and the
`pending Phase 0` label ended up on different lines — put them on one.

Commit: `docs: add operational context and repository README`

### Wave 4 — sequential, do this yourself

Plan Task 11. Do not delegate: it deletes the source document, and that
judgement should not be made by an agent that has only seen one task.

- Work through Task 11 Step 1's migration table, reading
  `docs/bolso-firme-escopo.md` section by section against the new documents.
  Every one of its eight sections must have a home. Add anything missing before
  deleting.
- `git rm docs/bolso-firme-escopo.md`, `rm -rf .qwen`, `rm -f test.ts`
- Run `./scripts/check-docs.sh; echo "exit=$?"`.
  **Expected: `check-docs: clean` and `exit=0`.** First fully green run.
- `git add .claude/settings.json` and commit with the message in Task 11 Step 5.
- Final read-through: follow every link in `README.md` and `CLAUDE.md` and
  confirm each lands on a document that says what the link promised. The script
  proves paths resolve; only reading proves they are honest.

## Agent prompt template

Give each subagent this shape. They start cold — a bare task number is not
enough.

> Read `docs/superpowers/plans/2026-08-13-documentation-foundation.md`, in full:
> the "Global Constraints" section, then **<Task N, Step M>**.
>
> Write **<exact file paths>** following that section's content requirements
> precisely. Reproduce every table in the plan verbatim — they are data, not
> suggestions.
>
> Hard rules: write in English only; use date `2026-08-13` and decider
> `Caio Lima`; reproduce the plan's exact technical values (coverage,
> pipeline order, temperature limits, observability fields).
> <Insert any task-specific constraint here — e.g. for ADR-0005: "This ADR's
> status is `Proposed`, NOT `Accepted`, and it keeps its `Open Questions`
> section. This is intentional; do not 'correct' it.">
>
> Do not run any git command — no add, no commit. Do not run the check script.
> Do not create, modify, or delete any file other than the ones listed above.
>
> Report back: the paths you wrote, and any place the plan was ambiguous enough
> that you had to make a judgement call.

## Reporting

After each wave, tell me in one short paragraph: which files landed, the
checker's exit code and findings, and anything an agent flagged as ambiguous.
Stop and ask before proceeding if a wave's verification shows a finding that is
not the known `docs/bolso-firme-escopo.md` baseline.

Reply to me in Portuguese; everything written to disk stays in English.
````

---

## Why these waves

Dependencies here are link-resolution dependencies, not build dependencies —
any document *can* be written before its targets exist. What forces the wave
boundaries is the verification gate: the checker must be able to reach a known
state when a wave closes, and forward links inside a wave resolve when its last
agent returns.

- **Wave 0 is sequential** because everything downstream is verified by the
  script, and three agents inferring the ADR format independently would produce
  three dialects of it.
- **Waves 1 and 2 are wide** because ADRs are mutually independent, and the
  architecture/product/engineering documents only cross-link — they do not
  depend on each other's content beyond the tables the plan already fixes
  verbatim.
- **Wave 3 is separate** because `CLAUDE.md` and `README.md` index the entire
  set; writing them before the set exists means writing links to files nobody
  has created yet.
- **Wave 4 is sequential and undelegated** because it deletes the source of
  truth. The migration audit needs someone who has seen the whole set.

The peak is five concurrent agents in Wave 2, and eleven plan tasks collapse
into five commits.
