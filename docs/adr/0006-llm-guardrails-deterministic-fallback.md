# ADR-0006: LLM guardrails and deterministic fallback

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

The product uses language models in three places: categorizing imported
transactions whose merchant strings no rule table recognizes, generating monthly
insights from aggregated spending, and narrating scenarios around a goal
projection. All three touch a user's money.

That domain changes what a wrong answer costs. A recommendation engine that
suggests a mediocre film is mildly annoying; a dashboard that reports a
confidently wrong figure about someone's savings is worse than a dashboard that
reports nothing at all, because the user acts on it. A plausible-sounding wrong
number is the specific failure mode to design against — it does not look like an
error, so nothing downstream catches it and the user has no reason to doubt it.

Model providers also fail in ordinary infrastructure ways. They have outages,
latency spikes, rate limits, and occasional responses that do not parse as the
JSON the prompt asked for. Any feature whose only implementation is a model call
inherits that provider's availability as its own, which means a statement import
would stop working because a third party is degraded.

Finally, prompts are behavior. A prompt edited in a string literal changes what
the product does to real financial data, with no diff anyone reviewed and no
test that noticed.

## Decision

We will treat every LLM call as an untrusted input source: prompts are versioned
in git, output is validated against a Zod schema before use, and every call has
a deterministic fallback that produces a correct-but-simpler result when the
model fails, times out, or returns unparseable output.

## Mechanism

### Chain-of-verification

Every call follows the same chain: generate → validate schema → correct →
deliver. The model produces a response; the response is parsed against the Zod
schema that defines the expected shape; if validation fails, one correction
attempt is made with the validation error fed back to the model. On repeated
failure the call routes to the fallback rather than surfacing an error to the
user. The user-visible outcome of a model failure is a simpler result, never a
broken screen.

Because the schemas come from the shared package described in
[ADR-0004](0004-zod-shared-validation-contract.md), "the response is invalid" is
the return value of a parse, not a judgement someone makes while reading output.

### Constraints

- Prompts live in `/packages/prompts/` and change only through a pull request
  with a regression test. A prompt file has a semantic version, and the test
  pins the expected output shape for a fixed set of inputs, so a prompt edit
  that breaks the contract fails in CI rather than in production.
- Temperature stays `≤ 0.3` for financial analysis and `≤ 0.2` for goal
  projection, and never exceeds `0.5` on sensitive data. Variety has no value
  here; reproducibility does, because a support question about a categorization
  should be answerable by re-running the same input.
- Every call logs `tokens_in`, `tokens_out`, `cost_usd`, `latency_ms`, and
  `validation_status`. The logging stage runs on every path, including the
  fallback path, so fallback rate is a measurable number rather than an
  impression.

## Consequences

### Positive

- The product degrades instead of breaking when a provider fails. An import
  still completes with rule-table categories; a projection still shows its
  computed number without the narration. The blast radius of a provider outage
  is a feature getting simpler, not a workflow stopping.
- Cost is observable per feature from the first call rather than discovered on a
  bill. `tokens_in`, `tokens_out`, and `cost_usd` per feature make an expensive
  prompt visible while it is still cheap to change.
- Prompt changes are reviewable diffs. A behavior change to a production feature
  goes through the same gate as a code change, because it is a code change.
- A schema-invalid response is a mechanical, testable event rather than a
  judgement call. The fallback trigger can be unit-tested by feeding the parser
  a malformed payload, with no model in the loop.

### Negative

- Every AI feature is built twice — once with the model and once
  deterministically — which roughly doubles the cost of each. The deterministic
  path is real engineering work with its own tests, not a stub.
- The fallback path is the one users hit during incidents and the one least
  exercised in normal testing, so it needs deliberate test coverage. A fallback
  that has never run is an assumption, not a safety net.
- Low temperature reduces output variety, which makes insight text more
  repetitive month over month than a freer setting would produce.
- Validation plus a correction attempt adds latency and tokens to the failure
  path, so a partially degraded provider costs more per request than a healthy
  one before the fallback takes over.

### Neutral

- The five observability fields are a logging contract, not a vendor choice. Any
  provider or self-hosted model can be adopted later as long as the wrapper
  keeps emitting them.
- The deterministic path is the feature's floor, so the model's contribution is
  always measurable as the difference between the two — which is also the honest
  way to decide whether a given AI feature is worth its cost.

## Alternatives Considered

### Unconstrained LLM calls with error surfacing

Call the model, use the response as-is, and show an error when the call fails.
Rejected because an error in a financial dashboard destroys trust: the user
cannot tell whether the failure is cosmetic or whether their data is affected,
and the honest answer requires reading logs. It is also rejected because
unvalidated output would let a hallucinated category or projection reach the
user as fact, which is precisely the failure this ADR exists to prevent.

### No LLM features at all

Genuinely considered. Deterministic rules cover most categorization: a merchant
rule table handles the recurring transactions that make up the bulk of a typical
statement, and every projection number is already computed arithmetically.
Rejected because auto-categorization quality on unseen merchant strings is where
the product differentiates — the long tail of unrecognized descriptions is
exactly the part users otherwise categorize by hand — and because the fallback
design bounds the risk: the worst case of adopting a model here is the product
the no-LLM option would have shipped anyway.

### A fine-tuned or self-hosted small model instead of guardrails

Reduce variance by controlling the model rather than by validating its output.
Rejected because it addresses one failure mode (inconsistent formatting) while
leaving the others untouched — outages, latency, and confidently wrong values
all survive a change of model — and because it front-loads infrastructure work
before any evidence exists that the hosted path is inadequate. A smaller model
remains available as a fallback target under this decision.
