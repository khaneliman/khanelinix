# Engineering Foundations

Use these principles as questions and design evidence, not a compliance score.

## Construction Goals

Basis:
[MIT 6.031 software-construction goals and specifications](https://web.mit.edu/6.031/www/fa21/classes/06-specifications/).

Evaluate whether design is:

- **safe from bugs**: invalid states and misuse are prevented, detected, or
  contained near their source;
- **easy to understand**: behavior, ownership, and terminology can be recovered
  without reconstructing whole system;
- **ready for change**: credible changes remain localized and observable
  contracts remain stable unless migration is intentional.

Tradeoffs remain explicit. Improving one property may increase complexity,
latency, cost, or operational burden elsewhere.

## Contracts and Abstractions

Basis:
[MIT 6.031 abstract data types](https://web.mit.edu/6.031/www/sp20/classes/10-abstract-data-types/)
and
[representation invariants](https://web.mit.edu/6.031/www/sp22/classes/11-abstraction-functions-rep-invariants/).

- Specify caller obligations, successful guarantees, errors, and side effects at
  boundary. Include temporal, resource, authorization, and compatibility
  conditions when those affect correctness.
- Keep public contract in abstract vocabulary. Keep storage layout, caches,
  handles, and other representation details private.
- Model an ADT only when operations form coherent domain abstraction. State
  abstraction function informally when concrete representation is non-obvious.
- Define invariants for legal state. Establish them at creation, preserve them
  through every transition, and prevent representation exposure.
- Prefer types and constructors that make invalid state unrepresentable when
  benefit exceeds conversion and API complexity. Otherwise validate once at
  trusted boundary and return structured errors.
- Default toward immutable values when sharing or aliasing creates risk. Do not
  copy large state or force functional style without evidence.

## Systems and Boundaries

Basis: MIT 6.033 on
[modularity](https://ocw.mit.edu/courses/6-033-computer-system-engineering-spring-2018/pages/week-1/lecture-1-outline/),
[naming](https://ocw.mit.edu/courses/6-033-computer-system-engineering-spring-2018/pages/week-2/lecture-2-outline/),
and
[fault tolerance](https://ocw.mit.edu/courses/6-033-computer-system-engineering-spring-2018/pages/week-8/lecture-14-outline/).

- Use modules to limit reasoning scope, authority, change propagation, and
  failure propagation. Soft file boundaries alone do not provide isolation.
- Name concepts by stable domain identity. Define namespace, binding authority,
  resolution context, lifecycle, and ambiguity rules when names cross processes,
  tenants, persistence, or administrative boundaries.
- For each credible fault: identify it, detect it, contain it, then choose
  fail-fast, fail-stop, mask, retry, compensate, or surface. Reliability has
  cost; do not add replication or distributed coordination without a target.
- Treat remote calls differently from local calls. Specify timeout, duplicate,
  reordering, partial success, stale response, and retry behavior.
- Keep authority and mutable state narrow. Prefer explicit ownership or message
  passing when concurrent writers would otherwise race.

## Change and Refactoring

Basis: Martin Fowler on [refactoring](https://refactoring.com/) and
[YAGNI](https://martinfowler.com/bliki/Yagni.html).

- Preserve externally observable behavior during refactoring. Make semantic
  changes explicit and test them as changes, not refactors.
- Remove duplication only when duplicated knowledge must change together.
- Add abstraction after concrete consumers expose stable common behavior or
  before one when boundary is required for safety, ownership, or substitution.
- Apply YAGNI to speculative capability, not to tests, clear contracts, or
  low-cost change-enabling structure justified by current work.
- Treat code smells and SOLID names as investigation prompts. A finding requires
  concrete impact on behavior, comprehension, change cost, testing, or
  operation.

## Responsible Computing

Basis:
[MIT SERC](https://ocw.mit.edu/courses/res-tll-008-social-and-ethical-responsibilities-of-computing-serc/)
and [ACM Code of Ethics](https://www.acm.org/code-of-ethics).

For consequential systems, identify affected people, including non-users, and
evaluate benefit and harm distribution, fairness, privacy, accessibility,
security, recourse, accountability, and operational control. Match safeguards to
impact: least privilege, previews, approvals, audit trails, explainability,
rollback, retention limits, or independent review. Avoid universal gates whose
cost or false assurance exceeds risk reduction.
