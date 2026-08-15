# Product Roadmap

- **Status:** Active
- **Date:** 2026-08-13
- **Owner:** Caio Lima

Each phase below becomes its own design spec and implementation plan when it is
started. This document is the map, not the execution plan: it states what each
phase is for, what it is expected to produce, and the condition under which it
is considered finished, but it deliberately stops short of describing how any of
it is built. That belongs in the spec written at the start of the phase, when
the preceding phases have already been built and their surprises are known.

The ordering is not arbitrary. Each phase depends on the guarantees established
by the one before it: there is no point alerting on a budget before transactions
are trustworthy, no point projecting a goal before budgets are accurate, and no
point charging money for any of it before there is an audit trail. The
acceptance criteria are the mechanism that keeps that dependency honest — a
phase is not finished when its features are visible, but when its criteria are
demonstrably met, because the next phase is built on the assumption that they
are.

Phases are also the unit at which quality bars change. The coverage floor of
70% applies from Phase 0 onward, Phase 2 raises its own bar because the budget
calculation is where a wrong number is most damaging, and the latency target
tightens from Phase 1 to Phase 6 as the system moves from correct to fast.

## Phases

| Phase | Focus | Technical deliverables | Acceptance criteria |
|---|---|---|---|
| 0 | Foundation & CI/CD | Monorepo, Docker, Prisma, JWT auth, shared Zod package, GitHub Actions | CI green, coverage ≥ 70%, `.env.example` with no secrets |
| 1 | Transactions & Dashboard | Transaction CRUD, CSV/OFX parser, TanStack Query, basic Recharts | Endpoint validated, import working, p95 < 1s |
| 2 | Budget & Alerts | Custom categories, percentages, DDD rules, notifications | Alert fires in real time, calculation accurate, tests ≥ 80% |
| 3 | Goals & Investments | Manual portfolio, visual projection, LLM auto-categorization (gated) | Fallback active, 100% Zod validation, token cost logged |
| 4 | Premium & Payments | Stripe/Asaas, feature flags, freemium gates, exportable reports | Idempotent checkout, webhook retry, audit log |
| 5 | Multi-user | Groups, RBAC, invitations, shared budgets, audit trail | Permissions isolated, no cross-tenant leakage |
| 6 | Optimization & Scale | Redis cache, OpenTelemetry, rate limiting, K8s/AWS preparation | Latency < 500ms, zero secrets in the repository, metrics visible |
| 7+ | Mobile & Open Finance | React Native/Expo, BCB certification, offline sync | Code reuse ≥ 70%, LGPD compliance, offline fallback |

## Estimates

The MVP — Phases 0 through 2, which is the first point at which the product is
genuinely useful to a single user with real statements — is estimated at 8–10
weeks. The full product through Phase 6, including payments, multi-user support,
and the optimization work that makes it operable, is estimated at 5–6 months
from the same starting point. Mobile and Open Finance in Phase 7+ add a further
3–4 months, most of which is certification and offline synchronization rather
than interface work.

These estimates assume solo part-time development and are planning aids, not
commitments; they exist to keep the sequencing realistic and will be replaced by
the concrete plan written at the start of each phase.
