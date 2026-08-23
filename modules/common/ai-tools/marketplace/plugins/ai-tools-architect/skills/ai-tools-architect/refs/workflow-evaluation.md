# Workflow Evaluation

Use this method before changing skill triggers, workflow ownership, provider
routes, model defaults, or reasoning effort. Generic benchmarks can suggest a
candidate. Only representative local tasks can justify promotion.

## Separate Evaluation Questions

Evaluate one declared question at a time when practical:

- Did the agent select the correct owner, methods, and overlays?
- Did one workflow contract produce a better verified result?
- Did one model and effort route improve quality enough to justify cost?
- Did a fallback preserve required capability after provider failure?

Do not combine routing, prompt, tool, model, and effort changes in one candidate
unless the combined system is the actual unit under review. Record every
candidate difference when isolation is not practical.

## Freeze the Corpus

Create a scrubbed JSON corpus with `scripts/workflow_eval.py validate <corpus>`.
Each case needs:

- a stable ID and realistic prompt
- tags that identify the covered lane or risk
- one expected lifecycle owner, or `null` when no owner applies
- expected methods and explicit overlays
- routes that must not activate

Include positive and negative cases for every changed trigger. Include explicit
invocation cases when a skill is explicit-only. Remove secrets, live mutable
identifiers, expected answers, and hints that exist only to help the evaluator.
Freeze the corpus and source revision before running candidates.

The canonical routing corpus lives at
`modules/common/ai-tools/eval/workflow-routing-baseline.json`. Keep every corpus
outside the skill directory. A corpus carries expected answers, so it must never
ship inside the installed skill package. Record `source_revision` as provenance
only; do not treat it as a pin that consumers must resolve.

## Blind the Run

Prepare task and answer-key artifacts outside the installed skill directory:

```bash
python3 <skill-dir>/scripts/workflow_eval.py prepare \
  <corpus.json> --output <run-directory> --seed <opaque-label>
```

Give runners `tasks.jsonl`, not `answer-key.json`. Assign opaque candidate
labels. Keep the candidate map with the evaluator until scoring and human review
finish. The seed hides case labels from accidental inspection; it is not a
security boundary.

## Hold Environment Constant

Record source revision, instruction projection, provider, model revision,
effort, tool availability, permissions, timeout, and concurrency. Keep every
factor constant except the declared candidate difference. Give result records
one environment ID for this shared surface. Keep candidate-specific settings in
the private candidate map. If provider behavior prevents parity, record the
difference and treat cross-provider conclusions as lower confidence.

Run at least three independent trials for each case and candidate. Increase the
count when output variance can change the decision. Do not reuse conversational
state between trials.

## Retain Evidence

Store one JSONL result record per trial. Preserve:

- observed owner, methods, and overlays
- transcript path and opened instruction resources
- deterministic task checks or blinded human judgment
- latency, token use, and cost when the provider exposes them
- capability degradation, retry, or parent fallback

Use `null` for unavailable measurements. Do not estimate missing provider data.
Keep raw artifacts outside the skill package and retain their manifest hashes.
Use the strict result shape below. Copy `run_id` and `blind_id` from the task.
Use one shared environment ID for all candidates in the run.

```json
{
  "schema_version": 1,
  "run_id": "run-0123456789abcdef0123",
  "blind_id": "case-0123456789abcdef",
  "candidate_id": "candidate-a",
  "environment_id": "environment-1",
  "trial": 1,
  "observed": {
    "owner": "engineering-workflow",
    "methods": ["diagnosing-bugs"],
    "overlays": []
  },
  "evidence": {
    "transcript_path": "transcripts/candidate-a-case-01.jsonl",
    "opened_resources": ["AGENTS.md"],
    "latency_ms": 1250,
    "input_tokens": null,
    "output_tokens": null,
    "cost_usd": null,
    "task_passed": true,
    "degradation": null
  }
}
```

The scorer rejects extra keys, stale run IDs, unequal trial sets, and
environment drift. Trial numbers must start at 1 and remain contiguous. Declare
every candidate, including a candidate whose runner produced no records. For
each metric, all candidates must report values for the same case and trial
coordinates. Set that metric to `null` for all candidates when parity is not
available.

Score routing records with:

```bash
python3 <skill-dir>/scripts/workflow_eval.py score \
  <manifest.json> <answer-key.json> <results.jsonl> \
  --candidate candidate-a --candidate candidate-b --minimum-trials 3
```

The scorer verifies the answer key against the frozen manifest. It then checks
declared candidates, repetition, environment and measurement parity, exact owner
and route sets, forbidden-route violations, task pass counts, latency, tokens,
and cost. It does not decide design quality.

## Decide Before Unblinding

Freeze acceptance rules before reviewing candidate labels. Require:

- no authority, safety, or forbidden-route regression
- no regression on mandatory deterministic checks
- sufficient routing and task quality for the affected lane
- acceptable latency and cost for expected task volume
- transcript evidence that the intended instructions and tools were available

Have a reviewer judge ambiguous artifacts without candidate identity. Unblind
only after deterministic scoring and human judgment are recorded.

Promotion always needs a human decision. Change one semantic route at a time,
retain the previous route, and define a rollback trigger. A provider outage,
quota failure, or unsupported model alias must degrade to a
capability-equivalent route or parent execution. It must not block the owning
workflow.
