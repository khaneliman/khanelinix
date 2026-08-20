# Runtime Forensics

Runtime forensics diagnoses live running processes. The goal is a cited
diagnosis with exact source attribution.

## Read-Only Constraint

Diagnosis is read-only by default. Do not modify production source code during
diagnostic investigation.

## Investigation Steps

1. **Capture live signal.** Attach profilers to observe active process state:
   - CPU profiles for spinning processes.
   - Thread dumps for deadlocks or lock contention.
   - Event traces for frame drops or UI glitches.
2. **Reduce artifact.** Extract the dominant execution thread or call stack from
   the capture.
3. **Prove the mechanism.** Validate the identified cause against live runtime
   state before proposing fixes.
4. **Attribute to source.** Map the hotspot to the exact source file, function
   symbol, and line number.
5. **Output diagnosis.** Return the observed signal, root cause mechanism,
   source location, and artifact paths.
