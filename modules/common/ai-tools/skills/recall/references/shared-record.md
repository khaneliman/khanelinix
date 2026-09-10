# Shared-record sweep

The shared record holds what happened around the same code under other names:
symptoms users keep reporting, fixes that shipped and got reverted, errors
still firing in production. A feature with a long bug tail keeps most of its
story there, so do not reconstruct it from transcripts alone.

Sweep it whenever the topic names a feature, file, subsystem, area, or bug.
This is the default, not a judgment call, and "my work on X" does not exempt
it. Skip it only for pure activity recall with no named target ("what did I do
this week"), where local state and chat history are the entire answer.

Hand the sweep to the `why` skill's source investigators and reuse its
per-source playbooks so you do not reinvent each query vocabulary. Steer their
question from "why was this built this way" to "what is the current state,
what has been tried and did not hold, and what are users still reporting".
Inherit its posture: one investigator per source, null results are findings,
skip an unavailable MCP and say so.

Run the investigators in parallel with the chat-history mining. Fold the
results into the brief.
