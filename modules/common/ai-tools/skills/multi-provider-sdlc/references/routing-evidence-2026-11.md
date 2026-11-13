# Routing evidence: November 13, 2026

Gemini 4 Hydrogen launched on November 12. This snapshot records the release
guidance, the first independent measurements, and the local checks behind its
routes. It covers one day of evidence and is not a local evaluation.

## Release guidance

- [Google's launch post](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-hydrogen/)
  describes Hydrogen as the execution model for writing code, running tests, and
  verifying changes, alone or as worker and verifier agents under Carbon or
  Argon. It reports 2.5 times the speed of Gemini 3.8 Flash and 57% against
  18.2% on Terminal-Bench 4.1. These are vendor numbers.
- [The developer guide](https://ai.google.dev/gemini-api/docs/whats-new-gemini-4-hydrogen)
  names Hydrogen the recommended upgrade from 3.8 Flash. It defaults to `high`
  thinking and adds `xhigh`, reserved for hard problems where `high` falls
  short. The guide warns that `xhigh` can overthink simpler prompts.
- [Antigravity's model guide](https://antigravity.google/docs/models/) assigns
  Hydrogen fast coding and maintenance work that needs no separate planning
  phase. It keeps Argon and Carbon for work where every step needs maximum
  reasoning depth. Its Orchestrator option has Argon plan and review while
  Hydrogen implements.
- [The model card](https://deepmind.google/models/model-cards/gemini-4-hydrogen/)
  lists Hydrogen behind Claude Sonnet 5.5 on Terminal-Bench 4.1 (57.0% vs 63.9%)
  and OSWorld-2.1 (77.6% vs 83.9%). It reports occasional slowness or timeouts,
  and 5.57 points more unjustified refusals than 3.8 Flash.

## Independent measurements

Artificial Analysis moved to Intelligence Index v5.0.1, so these scores do not
compare with [the October snapshot](aa-intelligence-index-2026-10.md). Its model
page renders charts only; the figures below come from
[VentureBeat](https://venturebeat.com/technology/google-launches-gemini-4-hydrogen-a-faster-smarter-pricier-flash-successor)
and
[The Decoder](https://the-decoder.com/googles-gemini-4-hydrogen-outscores-the-bigger-argon-just-four-weeks-after-its-launch/),
which report them from Artificial Analysis.

| Model             | Effort | Index | Cost per task | Terminal-Bench 4.0 |
| ----------------- | ------ | ----- | ------------- | ------------------ |
| Claude Sonnet 5.5 | max    | 55    | $10.02        | 64%                |
| GPT-6.1 Sol       | max    | 55    | about $1.27   | 56%                |
| Gemini 4 Hydrogen | xhigh  | 54    | $3.16         | 54%                |
| Gemini 4 Hydrogen | high   | 51    | $1.87         | 54%                |
| Gemini 4 Argon    | high   | 50    | not reported  | 57.1%              |
| Gemini 4 Hydrogen | medium | 41    | $0.80         | not reported       |
| Claude Haiku 5.5  | max    | 36    | $0.41         | 32.8%              |
| Gemini 3.8 Flash  | high   | 31    | $7.77         | not reported       |
| GPT-6 Luna        | max    | 28    | $0.15         | 12.6%              |
| Gemini 4 Hydrogen | low    | 27    | $0.29         | not reported       |

- [Neurohive](https://neurohive.io/en/news/gemini-4-hydrogen-benchmarks-pricing-api/)
  reports the same source timing Hydrogen at `high` at 8.3 minutes per index
  task against 14.8 for 3.8 Flash. `xhigh` adds three index points for 69% more
  cost and no Terminal-Bench gain. `medium` gives up ten points.
- [Bito's coding-agent runs](https://bito.ai/blog/gemini-4-hydrogen-vs-3-8-flash-carbon-argon/)
  score hard five-turn sessions at 71.6% for Hydrogen, 63.2% for Argon, and
  42.2% for 3.8 Flash, in 6.9, 16.2, and 18.4 minutes. Misleading claims per
  answer were 0.8, 1.5, and 2.7. Claude Opus 5.5 scored 85.0% overall against
  Hydrogen's 75.6%. Bito sells a model router and judges its own benchmark, so
  treat this as one vendor's direction.
- Google's own comparison tables still favor Argon on chart reading
  (Chartography 71.6% vs 66.6%). No shared score ranks the two on review
  precision or diagnosis.
- [Early user reports](https://news.ycombinator.com/item?id=50471431) describe
  Hydrogen as a dependable implementation worker under a stronger planner and
  reviewer. Some report overreach and overwork on long agentic runs. These are
  uncontrolled anecdotes.

## Local checks

- Antigravity CLI 1.5.8 lists Hydrogen at `low`, `medium`, `high`, and `xhigh`.
  A one-prompt run at `high` succeeded on the Google AI Pro account.
- That run moved the general Gemini five-hour and weekly quota windows by about
  0.3 points each and left Argon's weekly window at 55%. A one-prompt Argon run
  did the reverse: it moved only Argon's window, by about 0.2 points. That
  matches Antigravity's October 15 rollout note, quoted in
  [rollout coverage](https://www.techcityauthority.com/2026/10/antigravity-gemini-4-argon-google-ai-pro.html),
  of "a separate weekly-only Argon quota for Pro on top of the existing Gemini
  bucket". Antigravity lists all three windows under one Gemini group, but they
  meter separately, so the registry gives Argon its own `gemini-argon` pool.
- The gateway discovers Antigravity models at runtime and publishes Hydrogen
  only as `gemini-4-hydrogen-xhigh`, so the registry uses that ID. The thinking
  level a gateway request runs at was not established.
- T3 Code's Antigravity catalog lists only Argon and 3.8 Flash, so native T3
  dispatch cannot target Hydrogen yet.
- The Antigravity model guide schedules GPT-OSS-120b for removal on November 18
  and lists Gemini 3.1 Pro as Enterprise-only. Both registry entries are
  unchanged here.

## Adoption and rollback

Hydrogen replaces 3.8 Flash on every route: it scores higher, runs faster, and
costs less per task at every level from `medium` up. It takes the implementation
and reproduction fallbacks from Argon on the coding results and the vendor's own
role split. It stays the last fallback on those routes. It outscores Luna and
Haiku, but the primary subscriptions come first.

Argon keeps diagnosis, review, deliberation, and the multimodal preference. The
vendor assigns it planning and review, and the general index does not rank
review precision. Move those seats when a review, diagnosis, or multimodal
comparison, or a local trial, shows Hydrogen at or above Argon.

The registry carries one Hydrogen entry. Add a level-specific entry only when a
route needs a level the default does not provide. If Hydrogen overreaches,
misses required checks, or uses more quota per accepted result, return the
execution seats to Argon and the narrow seats to 3.8 Flash.
