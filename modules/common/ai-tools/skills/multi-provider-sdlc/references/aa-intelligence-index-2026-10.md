# Artificial Analysis snapshot: October 15, 2026

This user-supplied snapshot of the
[Artificial Analysis Intelligence Index](https://artificialanalysis.ai/) v4.3.2
compares general capability against API cost per index task. The index combines
ten evaluations, including Terminal-Bench 4.0, SciCode, AA-LCR, and Humanity's
Last Exam. Use it to place models in capability and efficiency tiers. It does
not replace task-specific evidence such as the review and coding results in
[the September evidence](routing-evidence-2026-09.md).

## Scores

Claude models are listed at xhigh with fallback, which sits on or near the
Pareto line; their max-effort runs cost more for small gains (Opus 58 at ~$5.90,
Sonnet 56 at ~$5.40). Costs other than the two Gemini rows are read from the
published log-scale chart and are approximate. "Pareto" means no other listed
model scores higher for less.

| Model             | Measured effort     | Index | Cost per task | Efficiency                         |
| ----------------- | ------------------- | ----- | ------------- | ---------------------------------- |
| Claude Opus 5.5   | xhigh with fallback | 56    | ~$3.50        | Pareto: highest score at this cost |
| Claude Fable 5.1  | xhigh with fallback | 53    | ~$6.00        | dominated by Opus and Argon        |
| GPT-6 Astra       | max                 | 53    | ~$3.30        | dominated by Opus and Argon        |
| Gemini 4 Argon    | high                | 53    | $1.99         | just below the Pareto line         |
| Claude Sonnet 5.5 | xhigh with fallback | 52    | ~$2.00        | dominated by Sol                   |
| GPT-6.1 Sol       | max                 | 52    | ~$0.75        | Pareto: best value above 50        |
| Claude Haiku 5.5  | max                 | 43    | ~$0.22        | near Pareto                        |
| Gemini 3.8 Flash  | high                | 41    | $1.24         | dominated by Haiku and Sol         |
| GPT-6 Luna        | max                 | 38    | ~$0.07        | Pareto: cheapest                   |

Argon leads Flash on every component except AA-LCR long-context reasoning (80%
vs 81%). The largest gap is Terminal-Bench 4.0 at 57% vs 20%.

## Limits

- Scores were measured at xhigh, max, or high effort. Local semantic-role
  profiles often run at medium, and Claude worker agents inherit the session
  effort, so both score and cost shift.
- API cost is a proxy for quota use within one subscription. It does not compare
  included-plan allowances across providers.
- A general index does not rank review precision or known-bug recall. Keep Opus
  and Astra review decisions on review-specific evidence.

## Routing implications

- The existing tiers hold: Luna for narrow packets, Sol for routine work, and
  Opus for the highest-judgment seats. Opus at xhigh scores about three points
  above Astra at similar cost; max adds about two points for roughly 70% more.
- Sonnet at xhigh matches Sol at more than twice the cost, which supports
  keeping it a bounded trial rather than a default.
- Argon matches Fable and Astra at lower cost and draws on a separate quota
  pool, so it precedes Fable as a review fallback.
- Fable stays an evidence-driven escalation, not a default.
- Flash stays only where Google quota must stretch across narrow, long-context
  reading work; Haiku precedes it on those routes.
