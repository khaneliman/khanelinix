# Rationale Template

The prose that ships alongside the type sketch. Keep it to one page. Use
sentence-case headings and no boilerplate. Replace each italic note with actual
content.

## Problem

_One paragraph. State what the work must do, and what about the existing system
or constraints makes the shape non-obvious. If
[Phase A](../SKILL.md#phase-a-ground-the-problem) surfaced constraints the
design must honor, name them here. Examples: existing types to interoperate
with, callers you cannot break, invariants that crossed the boundary. The reader
must see the same constraints you saw._

## Usage (Caller's View)

_Write this section first, before the type sketch. Show the README or quickstart
the consumer reads, plus two or three realistic call sites in their own code.
Show what they import, what they call, and what comes back. Derive the type
sketch in [Shape](#shape) from this usage. The two must agree. When they
diverge, reconcile the sketch to the usage, not the reverse. The caller's
experience is the spec. The types serve it._

## Shape

_The recommended architecture. Describe data structures first, then how data
flows through the signatures. Name the decisions the rest of the design depends
on. State which invariants the types encode, where validation lives, and what
the system deliberately does not do. Judge interface depth explicitly. State
what complexity the public surface hides, what remains exposed to callers, and
why the interface is no larger than needed. Cite the principle behind each
decision, for example "per boundary discipline". Do not restate the principle._

## Synthesis Decision

_Filled in by [arena](../../arena/SKILL.md). Record which candidate became the
base and why, what you adapted from each of the others, and what you rejected
and why._

## Tradeoffs Accepted

_One bullet per tradeoff the chosen shape makes. Use the form "we accept X in
exchange for Y". Name anything a future reader might mistake for an oversight,
including anything that looks like premature optimization or premature
simplification._

## Alternatives Considered

_Required. Name at least one concrete alternative shape, with one line on why it
lost. Judge each alternative on interface depth, not implementation simplicity
alone. Name the complexity it exposes to callers and the complexity it hides.
Two or three alternatives belong here when the design space had real contenders.
One alternative is enough when the constraints forced the answer; then phrase
the conclusion as "this was the only viable shape because...". Do not list
flavors of the same shape. This section covers design alternatives the chosen
shape rejected, not other runner candidates._

## Open Questions and Risks

_List what you noticed during the sketch that the human must weigh in on, plus
risks worth flagging before implementation starts. Phrase each item as a
question, so the human's answer becomes the resolution instead of a comment._

## Next Implementation Step

_The first thing to build against the sketch. One sentence. State what you would
start writing immediately after synthesis, or after Phase C sign-off when a
checkpoint was opted into._
