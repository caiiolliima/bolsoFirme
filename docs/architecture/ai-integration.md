# AI Integration Architecture

- **Date:** 2026-08-13
- **Maintainer:** Caio Lima

## Principle

An LLM is an untrusted input source that happens to be expensive. That single
sentence governs every design choice in this document. Untrusted means the
response is parsed and validated before anything downstream reads it, exactly
as a request body from the public internet would be. Expensive means the call
is bounded — a temperature ceiling, a timeout, a token budget — and observable,
so its cost is a number on a dashboard rather than a surprise on an invoice.
And because an untrusted, expensive dependency will eventually fail, every call
has a deterministic path that runs when it does: a simpler, correct result the
product can always produce on its own. The reasoning behind this posture, its
rejected alternatives, and its costs are recorded in
[ADR-0006](../adr/0006-llm-guardrails-deterministic-fallback.md); this document
describes how the decision is implemented.

The rule that follows from it is worth stating plainly, because it constrains
product design and not only code: no user-visible number is ever produced by a
model. Models classify, summarize, and narrate. Arithmetic belongs to the
domain layer, where it is deterministic and unit-tested. The layering that
makes this separation enforceable rather than aspirational is described in the
[architecture overview](overview.md): model clients are `infrastructure`
concerns, and nothing in `domain` depends on them.

## AI in the product

| Feature | Technical implementation |
|---|---|
| Auto-categorization | OFX/CSV parser → extract description → LLM with versioned prompt → fall back to a static rule when `confidence < threshold` |
| Intelligent insights | Monthly aggregation → hierarchical summary prompt → Zod-validated JSON → conditional display |
| Goal projection | Deterministic calculation + scenario simulation via LLM (temperature `≤ 0.2`) |

### Auto-categorization

An imported statement arrives as OFX or CSV, is parsed into a validated shape,
and yields a merchant description per transaction. The first pass over those
descriptions is a merchant-string rule table: a deterministic mapping that
covers the recurring transactions making up the bulk of a typical statement.
Only the strings the table misses reach the model, which returns a category and
a confidence score. When confidence falls below the threshold, or when the call
fails for any reason, the transaction takes the rule table's answer — an
explicit "uncategorized" is a valid answer there.

The ordering matters. Because the rule table runs first and the model handles
the remainder, a model failure degrades the feature to the rule table rather
than breaking the import. The user still gets every transaction, still gets the
recognized categories, and edits the long tail by hand exactly as they would
have without the feature. The worst case of the model being unavailable is the
product that would have shipped without it.

### Intelligent insights

Monthly spending is aggregated deterministically, and the aggregate — not the
raw transaction list — is what the summary prompt receives. The prompt is
hierarchical: it summarizes per category first, then composes those summaries
into the monthly narrative, which keeps the input bounded regardless of how many
transactions the month contains.

Insight output is display-only. It never feeds a calculation, never updates a
budget, and never writes to the database. If schema validation fails after the
correction attempt, the insight panel is not rendered at all. There is no
degraded or partial insight, because a half-formed sentence about someone's
spending is worse than an absent panel: the absent panel is obviously absent,
while the partial one reads as a finding.

### Goal projection

The projected number is always computed deterministically in the domain layer
from the goal's target, the contribution schedule, and the observed savings
rate. The model receives that number as an input and narrates scenarios around
it — what changes if contributions rise, what a lean month costs in weeks of
delay — at temperature `≤ 0.2`, the tightest setting in the product, because
narration that contradicts the arithmetic it describes is the failure mode here.

The model can never alter the projection. The narration is rendered beside the
figure, not in place of it, and the figure renders whether or not the narration
arrives.

## AI in development

| Practice | Rule |
|---|---|
| Prompt registry | Critical prompts versioned in git (`/packages/prompts/`), never in loose variables |
| Chain-of-verification | Generate → validate schema → correct → deliver. On failure, route to fallback |
| Temperature | `≤ 0.3` for analysis and finance. Never `> 0.5` on sensitive data |
| Observability | Structured log: `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, `validation_status` |
| Mandatory fallback | On LLM timeout, error, or invalid output → deterministic rule or smaller model. Never blocks the UX |

Development-time discipline is documented here for the same reason the runtime
guardrails are: assistance from a model is part of how this repository is
built, and an unexamined assistant is the same unbounded dependency at
authoring time that an unvalidated call is at runtime. The practices above make
the claim checkable rather than rhetorical. Generated code is reviewed,
explained, and covered by tests before it merges; a line the author cannot
explain does not ship, regardless of whether it passes. Prompts that shape
product behavior are files under review, so a behavior change to a live feature
travels through the same gate as any other code change — because it is one.

## Call lifecycle

```
request
  → load versioned prompt from packages/prompts
  → call model (temperature ≤ 0.3, timeout enforced)
  → parse response
  → validate against Zod schema
      ├── valid   → return result
      └── invalid → one correction attempt
                      ├── valid   → return result
                      └── invalid → deterministic fallback
  → log tokens_in, tokens_out, cost_usd, latency_ms, validation_status
```

**Load versioned prompt.** The prompt is read from `/packages/prompts/` by name
and version. Nothing assembles prompt text from string literals at the call
site, so the exact instructions sent to the provider are always recoverable
from the commit that produced them.

**Call model.** Temperature and timeout are set by the wrapper, not by the
caller, which is what makes the ceilings enforceable rather than conventional.
The timeout is a hard bound: an unanswered call is a failed call, and a failed
call has a defined outcome further down the chain.

**Parse response.** The raw response is parsed into a candidate object. A
provider returning prose where JSON was requested fails at this stage and is
treated identically to a schema violation — an unparseable payload and an
invalid one are the same category of event.

**Validate against Zod schema.** The candidate is validated against the schema
that defines the expected shape for this feature, drawn from the shared
package. This is where "the response is wrong" becomes a boolean instead of an
opinion, which is what makes the whole path testable without a model in the
loop: feed the parser a malformed payload and assert the fallback runs.

**One correction attempt.** On failure the validation error is fed back to the
model once, and only once. A single retry recovers the common case of a
formatting slip without turning a degraded provider into an unbounded cost or
an unbounded wait.

**Deterministic fallback.** A second failure routes to the deterministic path —
the rule table, the computed figure, or a smaller model — and the user sees a
simpler result rather than an error. This is the branch users hit during
incidents and the branch least exercised in ordinary testing, so it carries
deliberate test coverage of its own.

**Logging.** The logging stage runs on every path, including the fallback path
and including calls that failed outright. That is the property that makes
fallback rate a measurable number rather than an impression: if the log only
covered successful calls, the metric would describe the health of the calls
that worked, which is the one population that never needed measuring.

## Prompt versioning

Prompts are files, not strings. Each lives in `/packages/prompts/` under a
semantic version — `v1.0` for the first shipped revision, `v1.1` for a
backward-compatible refinement — and a call site names the version it depends
on. Two versions can therefore coexist while one is being evaluated against the
other, and a regression traced to a prompt is a revert like any other.

Changing a prompt requires a pull request carrying a regression test. The test
pins the expected output *shape* for a fixed set of inputs: given a known
merchant string, the response still validates against the categorization schema
and still populates the required fields. It pins shape rather than exact text
because exact text is not a property models guarantee, while shape is precisely
the property the runtime depends on. The consequence is that a prompt edit
which breaks the contract fails in CI instead of in production, on someone's
statement import.

## Cost and quality metrics

Every AI feature reports four metrics, per feature and not merely in aggregate:

- **Tokens** — `tokens_in` and `tokens_out`, which locate the expensive prompt
  while it is still cheap to change.
- **USD cost per month** — `cost_usd` summed over the period, the number that
  decides whether a feature earns its keep.
- **Schema validation rate** — the share of calls that validated on the first
  attempt. A falling rate is the earliest signal that a prompt, a model
  revision, or the input distribution has drifted.
- **Fallback rate** — the share of calls that ended on the deterministic path.
  This is simultaneously a provider-health metric and a product metric: a
  feature running mostly on its fallback is a feature whose model contribution
  is not worth what it costs.

Latency is recorded alongside them as `latency_ms`, because a call that
succeeds after the user has moved on has failed in every sense that matters.

A feature without these metrics does not ship. That is not a preference about
dashboards; it is what makes the guardrails auditable instead of aspirational —
an unmeasured fallback is an assumption, and an unmeasured cost is discovered
on a bill. The gate is enforced alongside the rest of the project's quality
rules in [engineering guardrails](../engineering/guardrails.md).
