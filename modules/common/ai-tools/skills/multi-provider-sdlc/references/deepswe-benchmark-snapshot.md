# DeepSWE benchmark snapshot

This user-supplied snapshot, retained during the 2026-09-11 audit (original
measurement date unrecorded), reports `pass@1` and average cost for
mini-swe-agent coding tasks. It is retained as historical evidence only; it is
not a quality-promotion claim and does not override canonical semantic-role
defaults or live task evidence.

| Model            | Low         | Medium      | High        | Xhigh        | Max          |
| ---------------- | ----------- | ----------- | ----------- | ------------ | ------------ |
| GPT-5.6 Luna     | 2% / $0.01  | 11% / $0.04 | 44% / $0.16 | 57% / $0.31  | 67% / $0.61  |
| GPT-5.6 Sol      | 45% / $1.07 | 61% / $1.86 | 69% / $3.47 | 71% / $4.70  | 73% / $8.39  |
| GPT-6 Astra      | unmeasured  | unmeasured  | unmeasured  | unmeasured   | unmeasured   |
| Claude Opus 5    | 58% / $1.66 | 69% / $3.29 | 73% / $6.08 | 73% / $9.07  | 74% / $11.84 |
| Claude Fable 5.1 | 60% / $3.76 | 65% / $6.09 | 69% / $9.18 | 70% / $13.41 | 70% / $21.63 |
| Gemini 3.8 Flash | 54% / $1.83 | 65% / $2.03 | 65% / $2.18 | not shown    | not shown    |
| Claude Sonnet 5  | 31% / $2.19 | 40% / $4.08 | 48% / $7.43 | 50% / $11.89 | 54% / $26.40 |

In this matrix Luna gains sharply from high through max. Sol and Opus reach
strong results at high, with smaller gains at higher effort. These observations
do not establish the best effort for local workers. Fable gains little beyond
xhigh. Gemini Flash shows no measured gain from medium to high. Sonnet is not a
cost-efficient default in this snapshot.

Astra has no benchmark measurement in the snapshot. The routing policy reserves
it for higher-cost, higher-latency review and orchestration work until direct
measurements are available. Astra shares the OpenAI `general` quota pool
conservatively pending live pool telemetry that verifies a separate allocation.
Spark, Terra, and GPT-OSS do not appear in the snapshot. Keep their existing
latency-first or explicit-only roles until comparable measurements exist.
