# Engineering Guardrails

- **Last updated:** 2026-08-13
- **Owner:** Caio Lima

## Purpose

This document is the contract the project holds itself to. It exists in writing
so that "we were moving fast" is never an available excuse: the rules below were
agreed before any product code existed, which is the only moment at which they
can be set honestly. A guardrail invented after an incident is a reaction; a
guardrail written down first is a standard. Everything here is deliberately
mechanical — a gate either passed or it did not, a metric is either emitted or
it is missing — because judgement calls made under delivery pressure are how
quality erodes in a solo project with no reviewer to appeal to.

These gates are aspirational until Phase 0 builds the pipeline that enforces
them. Nothing in this repository executes them today beyond the documentation
check described in section 6. That gap is stated plainly rather than hidden: the
value of writing the contract early is that Phase 0 has an explicit definition
of what "the pipeline is done" means, and the value of admitting the gap is that
no reader mistakes an intention for a running check.

## The Six Rules

1. **No merge without validation:** `test → lint → schema validation → manual
   code review`. The order matters. Tests run first because a broken behavior
   makes style feedback irrelevant; lint runs before schema validation because a
   file that does not parse cannot have its contracts checked; human review comes
   last so that the reviewer's attention is spent on design and intent rather
   than on defects a machine already finds for free.

2. **Versioned prompts:** critical prompts live in git under `/packages/prompts/`;
   changes require a pull request and a regression test. A prompt is behavior. An
   edit to a string literal buried in a service class changes what the product
   does with real financial data without producing a reviewable diff or failing a
   test, which is exactly the property that makes untracked prompts dangerous.

3. **Metrics from day one:** `tokens_in`, `tokens_out`, `cost_usd`,
   `latency_ms`, `validation_status`. No metrics means no production. These five
   fields are cheap to add while a feature is being written and expensive to
   retrofit once it is live, and without them the first honest answer to "what
   does this feature cost and how often does it fail" arrives on an invoice.

4. **Deterministic fallback:** when an LLM fails, route to a static rule or a
   smaller model. It never blocks the UX. The provider's availability must not
   become the product's availability, so every model-backed feature has a
   simpler path that produces a correct result on its own.

5. **Mandatory explainability:** if a generated line cannot be explained, it does
   not get merged. Ask for the explanation, understand it, adapt it. Code nobody
   understands cannot be reviewed, debugged at 2am, or safely refactored later,
   and its author has learned nothing from shipping it.

6. **Non-negotiable CI/CD:** `lint → test:coverage(≥70%) → build → scan →
   deploy`. Green merges, red blocks. A pipeline with manual overrides is a
   suggestion; the value comes precisely from the absence of a way around it on
   the day it is inconvenient.

## Definition of Done

A pull request is not done when the feature works. It is done when every item
below is true, and each is checkable by looking at the diff rather than by
asking the author how they feel about it.

- [ ] **Behavior is covered by tests.** The tests exercise the behavior that
      changed, including at least one failure path, not only the success case.
- [ ] **Cross-boundary shapes are validated by a Zod schema.** Anything crossing
      the network boundary, the parser boundary, or the model boundary is parsed
      into a known shape before any other code touches it.
- [ ] **No secret appears in the diff.** No key, token, connection string, or
      real user data — locally in `.env`, in production through a secrets
      manager, never in a tracked file.
- [ ] **Public behavior changes are reflected in documentation.** If the change
      alters what the system does from outside, the document that describes that
      behavior changes in the same pull request.
- [ ] **Any new LLM call has a deterministic fallback and emits the five
      observability fields.** `tokens_in`, `tokens_out`, `cost_usd`,
      `latency_ms`, and `validation_status` are logged on every path, including
      the fallback path, so the fallback rate is measurable.
- [ ] **The author can explain every line.** Not "it works" — what it does, why
      it is written that way, and what would break if it were removed.

## CI/CD Pipeline

The pipeline runs in a fixed order, `lint → test:coverage(≥70%) → build → scan →
deploy`, and each stage gates the next. Ordering is a cost decision as much as a
correctness one: the fastest and most frequently failing checks run first so
feedback arrives in seconds, and the expensive stages only ever run on a change
that already passed the cheap ones.

| Stage | What it gates | What failure means |
|---|---|---|
| `lint` | Style, formatting, and static analysis across the workspace | The change does not meet the baseline the whole codebase holds. Fix and push; nothing downstream runs. |
| `test:coverage(≥70%)` | Behavior, plus the coverage floor | Either a behavior regressed or new code arrived without tests. Both block the merge. |
| `build` | The workspace compiles and every package produces its artifact | Type errors or a broken package boundary. Nothing is deployable, so the pipeline stops. |
| `scan` | Dependency vulnerabilities and secret detection | A known-vulnerable dependency or a credential in the diff. Treated as a build break, not as a warning to triage later. |
| `deploy` | Promotion of the built artifact to the target environment | Only reachable when every prior stage is green. A red pipeline never deploys, and there is no manual override. |

The coverage floor is `≥ 70%` overall. It is a floor, not a target: it exists to
catch untested code arriving in bulk, not to certify that 70% is enough. Phase 2
raises its own target to `≥ 80%`, because that phase carries the budget
calculation rules — the part of the domain where a silent arithmetic error is
both most likely and most damaging. Later phases may raise their own bars the
same way; no phase lowers the overall floor. The phase-by-phase acceptance
criteria that these gates enforce are listed in
[the product roadmap](../product/roadmap.md).

## Metrics

Instrumentation is part of a feature, not a follow-up to it. The four families
below cover what the project needs to know about itself, and each names the
tooling intended to collect it so that "we will add observability later" has no
place to hide.

| Type | Metric | Tooling |
|---|---|---|
| Product | Free→premium conversion, D30 retention, dashboard activation | PostHog / Mixpanel |
| Backend | p95 latency, 5xx error rate, req/s throughput, DB pool usage | Pino + OpenTelemetry + Grafana |
| AI/LLM | Tokens per feature, USD cost per month, schema validation rate, fallback rate | LangSmith / custom logger |
| Quality | Coverage %, PR review time, CI failure rate, dependency vulnerabilities | GitHub Actions + SonarQube (future) |

The AI/LLM row is the one that most often goes missing in practice, and it is
the one rule 3 makes non-negotiable: a model-backed feature without tokens,
cost, validation rate, and fallback rate is a feature nobody can reason about
after it ships.

## Documentation Checks

Until product code exists, the documentation set is what this repository ships,
so it gets a check of its own. `scripts/check-docs.sh` is a Bash script that
validates every tracked and untracked markdown file in the repository, excluding
`docs/superpowers/` — that directory holds process artifacts such as specs and
plans rather than product documentation, and is intentionally exempt. Untracked
files are included on purpose: the script is meant to run before a commit, and a
freshly written document that had not been staged yet would otherwise pass by
never being looked at.

It performs three checks:

1. **Relative links resolve.** Every markdown link target that is not an
   external URL, a `mailto:` address, or a bare anchor is resolved relative to
   the linking file's own directory, with any `#fragment` stripped first. A
   target that does not exist on disk is reported as a broken link. This is the
   check that catches the most common defect in this set: a document under
   `docs/engineering/` linking to `product/roadmap.md` instead of
   `../product/roadmap.md`.
2. **Placeholder discipline.** The script greps for the standard uppercase
   markers that flag unfinished work and fails on any hit, with one exception:
   a line that also contains the string `pending Phase 0` is allowed through.
3. **English-only prose.** The script greps for the tilde and cedilla
   characters, which are effectively absent from English prose and therefore a
   cheap, low-false-positive signal that untranslated Portuguese text has leaked
   into a document.

Run it from anywhere in the repository — it resolves its own location and
changes to the repository root before scanning:

```bash
./scripts/check-docs.sh; echo "exit=$?"
```

Exit code `0` means clean and prints `check-docs: clean`. Exit code `1` means
findings, printed to stdout grouped by category so each one names the file and
the offending line.

Exactly two placeholders are sanctioned in the entire documentation set, and
both carry the literal label `pending Phase 0` on the same line as the marker:
the commands section of `CLAUDE.md` and the local-setup section of `README.md`.
Both describe commands that cannot exist until Phase 0 scaffolds the workspace,
so stating that plainly is more honest than inventing commands nobody can run.
The label and the marker must sit on the same line — the allowance is a
line-level match, so splitting them across two lines turns a sanctioned
placeholder into a failure. Anywhere else in the set, an unfinished marker is a
defect and the script treats it as one.

## Related Reading

- [AI integration architecture](../architecture/ai-integration.md) — how the
  LLM rules above are implemented: the call lifecycle, prompt versioning, and
  the per-feature cost and quality metrics.
- [ADR-0006: LLM guardrails and deterministic fallback](../adr/0006-llm-guardrails-deterministic-fallback.md)
  — the decision these guardrails come from, including the alternatives that
  were rejected and the costs the decision accepts.
