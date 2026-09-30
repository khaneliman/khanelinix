# Routing evidence: September 29, 2026

This snapshot informs the canonical routing policy; it is not a claim that these
models have won a local evaluation. The user approved adopting this guidance
after a research review. Sonnet 5.5 launched September 28 and Sol 6.1 September
29, so independent evidence is limited. Preserve historical benchmark labels
rather than attributing older measurements to newer models.

## Evidence and limits

- [OpenAI model guidance](https://learn.chatgpt.com/docs/models) recommends Luna
  for focused, repeatable work, Sol 6.1 for repeated complex work, and Astra for
  the hardest end-to-end tasks. This is vendor guidance, not a controlled
  cross-provider comparison.
- [Anthropic's Sonnet 5.5 results](https://www.anthropic.com/claude-sonnet-5-5)
  report 70.6% on Terminal-Bench 4.0 versus Opus 5.5's 66.4% at xhigh. The
  headline is not an equal-effort comparison. On FrontierCode 1.1, Sonnet scored
  52.1% at xhigh but 46.2% at max; extra review subagents caused timeouts or
  out-of-scope edits. Opus scored 54.4%. This supports bounded Sonnet trials,
  not replacing Opus for sustained judgment or defaulting every task to max.
- [CodeRabbit's review evaluation](https://www.coderabbit.ai/blog/sonnet-5-5-model-review)
  found 6/13 hard known bugs with Sonnet 5.5, 8/13 with Opus 5.5 Standard, and
  10/13 with Opus Max. Actionable precision was 41.2%, 66.7%, and 52.0%,
  respectively. Thirteen judge-scored cases provide direction, not a universal
  ranking. The separate 44-PR run established latency and comment-volume
  differences; its quality scoring was pending.
- [Real-SWE](https://realswe.withspecific.com/) reports 46.25% for Astra, 45%
  for Fable 5.1, and 38.75% for Gemini 3.8 Flash. These are native
  model-plus-harness results at high effort, not isolated-model scores. The
  evaluation omits Opus/Sonnet 5.5 and Sol 6.1, so it cannot rank the complete
  current lineup.
- [Google's model information](https://deepmind.google/models/gemini/flash/)
  lists image, audio, video, PDF, and text inputs with a million-token input
  window. A model's input support does not prove the local harness forwards that
  modality; check the actual route before dispatch.
- [Simon Willison's hands-on report](https://simonwillison.net/2026/Sep/28/claude-sonnet-5-5/)
  records a max-effort SVG attempt exhausting 128,000 thinking tokens without
  producing an artifact while xhigh succeeded. This is a narrow example, not a
  coding benchmark. First-day community impressions remain uncontrolled
  anecdotes and do not justify automatic promotion.

## Subscription economics

The user favors existing Codex and Claude subscriptions over the $20 Google
plan. [OpenAI pricing](https://learn.chatgpt.com/docs/pricing) explicitly warns
that API prices and credit rates do not establish included-plan allowances. Fast
mode consumes 2.5 times Standard included usage at this snapshot. Measure actual
quota and accepted results; keep Standard for background work unless latency
warrants the extra usage.

[Google's Antigravity plan guidance](https://antigravity.google/blog/changes-to-antigravity-plans)
places Gemini models in a shared quota pool, with non-Gemini models separate.
Switching Flash to Pro is not an independent quota fallback. Old consumer Gemini
CLI request allowances do not apply to Antigravity following the
[June 18 transition](https://github.com/google-gemini/gemini-cli/discussions/28017).

## Adoption and rollback

Keep Luna bounded, Sol routine, and Opus/Astra for serious review. Fable remains
available when its performance on the actual task justifies escalation. Keep the
native Opus implementation default; the Sonnet trial route does not replace it.
Gemini is a specialist or overflow option, not a quota-balancing obligation.

Before promoting Sonnet or raising an effort default, compare representative Nix
configuration, Rust debugging, known-bug review, and UI tasks. Hold prompts,
tools, checks, and scope fixed; record accepted results, rework, false
positives, elapsed time, and actual plan usage. Missing telemetry stays unknown.
Require no correctness or authority regression and a useful quality or
efficiency gain. If trials drift, miss required checks, or consume more quota
per accepted result, return to the prior Sol/Opus route. Public scores alone do
not settle that decision.
