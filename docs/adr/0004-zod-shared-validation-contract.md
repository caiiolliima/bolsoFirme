# ADR-0004: Zod as the shared validation contract

- **Status:** Accepted
- **Date:** 2026-08-13
- **Deciders:** Caio Lima

## Context

The same shapes are validated in more than one place. A transaction is checked
in the browser before the form submits, checked again by the API before it
reaches a use case, and checked a third time when it arrives as a row of an
imported CSV file. A budget is checked when it is created and re-checked when a
projection reads it back. An LLM response that claims to be a category
assignment or an insight payload is, from the application's point of view, just
another untrusted document arriving over the network.

Every one of those checks encodes the same knowledge: which fields exist, which
are required, what a valid amount looks like, which enum values a category may
take. Writing that knowledge three times means three chances for the copies to
disagree, and the disagreement is silent — the frontend accepts a value the
backend rejects, or worse, the backend accepts a value the frontend never
intended to allow. In a financial product the failure mode is not a broken page;
it is a stored record that no layer agrees on.

A fourth constraint comes from the LLM boundary. Model output is generated text.
It has no type, no guarantee of shape, and no contract beyond what the prompt
requested. Whatever mechanism validates user input has to be the same mechanism
that validates model output, otherwise the riskiest input path in the product
ends up with the weakest checking.

## Decision

We will define every cross-boundary shape once as a Zod schema in the shared
package, and derive TypeScript types from those schemas rather than declaring
types separately.

A shape is "cross-boundary" when it travels between the browser and the API,
between the API and the database layer, or between the application and a model
provider. Types for those shapes are produced with `z.infer` from the schema
that validates them; a hand-written `interface` describing a shape that already
has a schema is a review finding, not a style preference.

## Integration Notes

NestJS consumes these schemas through `ValidationPipe` configured with
`whitelist: true` and `forbidNonWhitelisted: true`, so unknown fields are
stripped and then rejected rather than silently forwarded. The two settings work
together on purpose: whitelisting alone would quietly discard an unexpected
field and let a malformed client keep working against a contract it does not
actually satisfy, while forbidding non-whitelisted properties turns that
mismatch into an explicit `400` at the edge, where it is cheap to diagnose.

The frontend uses the same schemas for form resolution and for parsing API
responses, so a contract change surfaces as a type error at build time in both
applications rather than as a runtime surprise in one of them.

## Consequences

### Positive

- One source of truth for shape and constraint. When a category enum gains a
  value or an amount changes its allowed precision, exactly one file changes and
  both applications inherit the change.
- Runtime validation and compile-time types cannot drift apart, because the
  types are inferred from the validator. There is no second declaration to
  forget to update; deleting a field from the schema breaks compilation
  everywhere the field was read.
- LLM output gets the same validation rigor as user input, which is what makes
  the fallback in
  [ADR-0006](0006-llm-guardrails-deterministic-fallback.md) mechanical rather
  than judgemental. "The model returned something invalid" becomes a boolean
  produced by `safeParse`, not an opinion formed by reading the response.
- Validation errors are structured data, so the API can turn a parse failure
  into a field-level error payload without a bespoke mapping layer per endpoint.
- Schemas double as executable documentation of the contract, which keeps the
  written documentation honest: a reviewer can diff the schema instead of
  trusting prose.

### Negative

- The shared package becomes a coupling point that both applications must
  rebuild against. A change there fans out into the web and API build graphs,
  and a careless change breaks both at once.
- Zod schemas carry a runtime cost on hot paths. Parsing a large imported
  statement row by row is measurably more expensive than trusting the parser,
  and the cost lands exactly where volume is highest.
- Complex conditional schemas — discriminated unions, refinements that depend on
  sibling fields — are harder to read than plain interfaces, and a schema that
  is hard to read is a schema reviewers approve without fully understanding.

### Neutral

- The shared package needs versioning discipline of its own once more than one
  consumer depends on it, but inside a single monorepo with a single deployable
  that discipline is enforced by the build rather than by publishing.
- Not every shape belongs in the shared package. Purely internal structures that
  never cross a boundary can remain plain TypeScript types; the rule is scoped
  to shapes that arrive from or leave toward an untrusted side.

## Alternatives Considered

### Plain TypeScript interfaces

Declare the shapes as interfaces and rely on the compiler. Rejected because
interfaces vanish at runtime and provide no protection at the network or LLM
boundary, which is exactly where untrusted data arrives. A response typed as
`Transaction` is an assertion about what the developer expects, not a check of
what actually arrived, and in a financial domain that gap is the whole problem.

### class-validator (the NestJS default)

Decorate DTO classes with validation decorators, which is the idiomatic NestJS
path and integrates with `ValidationPipe` out of the box. Rejected because its
decorator-on-class model does not travel to the frontend cleanly: the classes
carry decorator metadata and a runtime dependency that a React application has
no reason to adopt, and Next.js server/client component boundaries make shipping
decorated classes awkward. Using it would mean the frontend re-declares every
shape it already validates on the server, which reintroduces exactly the
duplicate definitions this decision exists to remove.

### Generating validators from a schema language (JSON Schema, OpenAPI)

Define shapes in a neutral schema format and generate both validators and types.
Rejected because it adds a code-generation step and an intermediate artifact to
review, and because the generated TypeScript types are consistently less precise
than what Zod infers directly. The neutrality only pays off with consumers in
other languages, which ADR-0002 explicitly rules out.
