# Type-Driven Rust Design

Use types to remove invalid states when the value exceeds the complexity cost.
Do not turn every runtime workflow into a generic type graph.

## Contents

- [Pattern Selection](#pattern-selection)
- [Typestate](#typestate)
- [Builders and Validation](#builders-and-validation)
- [Static or Dynamic Dispatch](#static-or-dynamic-dispatch)
- [Opaque and Async Return Types](#opaque-and-async-return-types)
- [Ownership and Concurrency](#ownership-and-concurrency)
- [Design Proof](#design-proof)

## Pattern Selection

| Need                             | Default                       | Escalate when                                                            |
| -------------------------------- | ----------------------------- | ------------------------------------------------------------------------ |
| Closed set of data variants      | `enum` + exhaustive `match`   | Operations must be unavailable in invalid phases                         |
| Validated scalar/domain identity | Newtype + checked constructor | Raw value can violate invariants                                         |
| Complex construction             | Constructor or builder        | Optional fields, staged validation, or fluent ergonomics matter          |
| Replaceable behavior             | Generic trait bound           | Runtime heterogeneity or compile-size pressure favors `dyn Trait`        |
| Protocol/lifecycle ordering      | Runtime enum                  | Misordered calls are dangerous and states are manageable at compile time |
| Shared mutable state             | Ownership/message passing     | True shared ownership is required and synchronized access is explicit    |

## Typestate

Use typestate when all are true:

- transitions are few, stable, and known at compile time
- operations differ materially by state
- consuming the previous state matches ownership semantics
- callers benefit enough to absorb generic types and conversion friction

Represent states with marker types or state-specific structs. Consume `self` for
transitions that invalidate the previous state. Implement methods only for
states where they are valid. Use `PhantomData` only when the marker is not
otherwise stored and its ownership/variance semantics are understood.

Prefer a runtime enum when state is persisted, serialized, user-selected, stored
heterogeneously, numerous, plugin-defined, or primarily observed at runtime. A
hybrid often works best: runtime state at storage boundaries and typed handles
inside a narrow critical protocol.

## Builders and Validation

- Prefer a constructor when required data is small and clear.
- Use a builder for many optional fields, discoverable configuration, or staged
  validation—not to mimic named arguments mechanically.
- Return `Result` from `build` when runtime validation can fail.
- Use a typed builder only when compile-time required-field enforcement pays for
  error-message and type-complexity cost.
- Keep defaults explicit and domain-safe. Do not make a value constructible in a
  semantically invalid default state merely to derive `Default`.

## Static or Dynamic Dispatch

Choose generics when implementations are known at compile time and inlining or
zero-cost composition matters. Choose trait objects when runtime selection,
heterogeneous collections, plugin boundaries, compile-time containment, or
binary-size control matters.

Measure before attributing performance to dispatch. Monomorphization can improve
runtime while increasing compile time and binary size. Keep object safety,
lifetimes, auto traits, and downcasting needs visible in the API decision.

Use native async trait methods when static dispatch fits. Do not assume they are
`dyn` compatible on the selected toolchain. Add boxing or an object-safe adapter
only at the boundary that needs runtime heterogeneity, then measure allocation
and latency rather than importing ecosystem-wide performance claims.

Use trait upcasting instead of conversion shims when the repository's MSRV
supports the required coercion. Keep explicit adapters when they enforce policy
or compatibility beyond the coercion itself.

## Opaque and Async Return Types

- In Rust 2024, return-position `impl Trait` captures all in-scope generic
  parameters by default. Review public APIs for unintended lifetime capture
  during edition migration.
- Use a precise `use<..>` capture bound when the hidden type needs a narrower
  contract and the declared MSRV supports it. Do not add capture tricks by rote.
- Put `Send` requirements where work crosses a multithreaded executor boundary.
  Do not force `Send` onto single-threaded consumers for convenience.
- Verify return-type notation or other async bound syntax against the selected
  stable toolchain. Route nightly-only syntax through
  [toolchain-evolution.md](toolchain-evolution.md).

## Ownership and Concurrency

- Prefer one clear owner and borrowed access before `Rc`, `Arc`, interior
  mutability, or global state.
- Use channels/message passing when ownership transfer models the workflow.
- Before raw-pointer splitting, use a stable disjoint-borrow API when the
  collection and repository MSRV provide one.
- Use `Arc<Mutex<T>>` only when shared synchronized mutation is genuinely the
  simplest contract; keep lock scope short and document ordering.
- Never hold blocking locks across `.await`. Distinguish sync mutexes from async
  mutexes based on protected work, not surrounding function syntax.
- Model cancellation, task shutdown, backpressure, and join ownership as API
  behavior. Detached tasks are lifecycle decisions, not convenience.
- Avoid `Send + Sync + 'static` bounds until the execution boundary requires
  them; unnecessary bounds leak runtime choices into domain APIs.

## Design Proof

For each type-level constraint, show:

1. the invalid state or call sequence being prevented
2. the constructor or transition that establishes the invariant
3. the escape hatches (`unsafe`, deserialization, FFI, public fields)
4. focused compile-fail, property, or runtime tests at the boundary
5. the ergonomics cost at storage, mocking, async, and serialization edges
