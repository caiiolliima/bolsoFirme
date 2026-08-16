# Product Vision

- **Status:** Active
- **Date:** 2026-08-13
- **Owner:** Caio Lima

## Problem

People lose control of their finances through a lack of visibility, structure,
and motivation. The money is not usually lost to one dramatic mistake; it drains
away through dozens of small decisions made without any picture of what they add
up to.

The concrete failure is that the data already exists and still answers nothing.
A single person routinely spreads spending across a salary account, a second
bank used for transfers, three or four credit cards with different closing
dates, a digital wallet, and the occasional cash withdrawal. Each of those
sources can produce a statement, and each statement is honest about its own
slice. None of them is capable of answering the only question that matters at
the end of a Tuesday in the middle of the month: *am I on track this month?*
Answering it manually means exporting several files, reconciling duplicated
transfers between one's own accounts, guessing at what a merchant string meant,
and rebuilding the same spreadsheet every thirty days. Most people do it once,
find it useful, and never do it again.

Structure fails next. Even people who know roughly what they spend rarely have a
per-category limit that means anything, because a limit without a running total
is a wish. And motivation fails last: saving for something specific is the part
of personal finance that actually changes behavior, yet goals typically live in
a different place from the spending that funds them, so progress is invisible
exactly when discouragement is most likely.

The result is a person who is not reckless and not uninformed, but who is
permanently one week behind their own money.

## Solution

Bolso Firme is a personal finance product built around one consolidated view of
a person's money, assembled from the sources they already have and organized so
that the answer to "am I on track" is visible without work.

- **A macro-to-micro dashboard.** The entry point is a single screen that states
  the position: income, spending, what remains, and how that compares to the
  same point in previous periods. Everything below it is a drill-down of that
  same number rather than a separate report.
- **Per-category budgeting.** Categories are defined by the user, given a value
  or a percentage of income, and tracked continuously against imported
  transactions. A budget is only useful when it can be exceeded visibly, so
  alerts fire while there is still time to change the outcome, not in a
  month-end summary.
- **Visible goals.** A goal is a named amount with a date and a funding rate.
  Progress is computed from the same transaction data as the budgets, so the
  relationship between this month's spending and the goal's arrival date is
  direct and always current.
- **A consolidated portfolio view.** Investments are part of net worth, not a
  separate hobby. The portfolio sits alongside spending and goals so that
  "should I put this month's surplus into the emergency fund or the goal" is a
  question the product can actually inform.

Transactions enter through statement import (OFX and CSV) with automatic
categorization, so the recurring cost of using the product stays close to zero.
That is the difference between a tool someone uses for a month and one they use
for years.

## Differentiator

Three things distinguish the product from the category of budgeting apps it sits
in.

**Progressive clarity through temporal zoom.** The interface is organized as a
continuous zoom — year, month, week, transaction — where each level answers a
different question with the same underlying data. The year answers "is my
trajectory right"; the month answers "am I on track"; the week answers "what
changed"; the transaction answers "why". Most tools pick one altitude and force
the user to reconstruct the others. Making the zoom the primary navigation means
a user can arrive with a vague sense of unease and land, in three interactions,
on the specific line item responsible for it.

**Motivational design.** Financial tools tend to be either accusatory or
neutral, and neither changes behavior. Bolso Firme is designed around visible
progress: goals advance, streaks of on-budget months accumulate, and the effect
of a decision on a goal's arrival date is shown at the moment of the decision.
The intent is not gamification for its own sake, but making the delayed reward
of saving legible enough to compete with the immediate reward of spending.

**One product instead of three.** Spending tracking, goal saving, and investment
tracking are normally three separate applications with three separate mental
models, and the gaps between them are where financial decisions actually get
made. Unifying them means the surplus produced by the budget, the goal it could
fund, and the portfolio it could enter are all expressions of the same balance,
and moving value between them is a decision the product can model rather than a
context switch the user has to perform.

## Engineering objective

The product is built with production rigor from day one, and that is a stated
objective rather than a side effect.

Every feature ships with tests, schema validation at every boundary it crosses,
observability sufficient to explain its behavior in production, and a
deterministic fallback for anything that can fail in a non-deterministic way. No
feature is considered done because it works on the developer's machine; it is
done when its failure modes are known and handled.

LLMs appear in the product where they earn their place — categorizing merchant
strings a rule table cannot resolve, narrating scenarios around a number that
was computed deterministically — and nowhere else. They are treated as untrusted
input sources that happen to be expensive: prompts are versioned in git, output
is validated against a schema before it is used, cost and latency are logged per
call, and every feature has a path that runs correctly when the model is
unavailable or wrong. LLMs are controlled copilots, never blind generators. The
same rule applies to the code itself: generated code is reviewed, understood,
and explained before it is merged, or it is not merged.

This is a portfolio project, and *how* it is built is part of the deliverable.
The repository is meant to be opened by an engineer who wants to know how the
author makes decisions, and to answer that question through recorded
architectural decisions with their rejected alternatives, explicit quality
gates, and documentation that was written before the code rather than after it.
The complete contract the project holds itself to is written down in
[engineering guardrails](../engineering/guardrails.md).

## Scope boundary

The product targets one person managing their own personal finances. That is the
whole of the current scope, and the design decisions above — a single
consolidated balance, one set of categories, one portfolio — assume it. Shared
and household budgets, with the group membership, permission model, and
per-owner query scoping they require, arrive in Phase 5 and are treated as a
distinct architectural step rather than a configuration flag.

Personas beyond the individual user are deliberately not defined. There is no
small-business persona, no financial-advisor persona, and no assumption about
income bracket or country beyond Brazilian statement formats and LGPD
obligations. Inventing those personas now would produce requirements no one has
asked for and constraints the product would then have to carry. They will be
defined when there is evidence to define them with. The sequencing of everything
described here is in the [roadmap](roadmap.md).
