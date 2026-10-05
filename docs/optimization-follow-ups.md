# Later Optimization Work

No applications, toolchains, sessions, or compute backends are removed by this
milestone. These are bounded follow-up experiments, not recommendations to
consolidate the fleet now.

## Starting evidence and its limits

The October 4 review measured the deployed Linux generation
`k58vqix3hwqi6rwrbw9rwdi1ghja7v22`, not this checkout. Its recursive NAR size
was 79,426,125,592 bytes across 6,637 paths. Its recovery specialisation was
already contained in that closure; adding its size again would double-count
shared paths. Large individual paths, such as LM Studio, HIP libraries, and
LibreOffice, are not their marginal removal savings. Retained source paths also
have real dependents; a name containing `source` does not establish that it is
disposable.

The realized review-corrected Linux candidate separately measures 79,583,644,928
NAR bytes across 6,637 paths. Its source and output are recorded in
[milestone evidence](reliability-milestone.md). The two generations use
different sources; their total difference does not isolate an application's cost
or prove an optimization benefit. Marginal candidate-removal closures and
comparative evaluation/build/runtime costs remain follow-up measurements.

The same corrected source built natively on Darwin: `khanelimac` has 4,116
closure paths / 45,348,352,728 NAR bytes, and `khanelimac-m1` has 790 paths /
6,842,357,112 NAR bytes. Their source-only cold evaluations on the M1 took 64.41
and 7.61 seconds. These are different intended machine capabilities, not a
controlled application-removal comparison. The native build included local Codex
compilation, but warm dependencies and earlier shared-builder transfer stalls
prevent treating total elapsed time as a comparative build benchmark.

Read-only runtime sampling during this milestone found Hyprland, Kitty, Ollama,
llama-swap, and SwarmUI processes on the deployed workstation. That demonstrates
use at the sample time, not performance, complete feature coverage, or that an
alternative is interchangeable. Darwin runtime evidence must be collected on
Darwin; Linux evaluation cannot establish Homebrew installation or Colima
health.

## Candidate comparisons

| Area                   | Compare                                                                   | Capabilities that must survive                                                                    | Required runtime comparison                                                                          |
| ---------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Terminal applications  | Explicitly selected Kitty, Ghostty, Foot and other terminals              | Graphics protocol, remote shell use, font rendering, session integration and existing keybindings | Repeat the same local/remote sessions and rendering workload; measure startup and memory             |
| Development toolchains | Profile payloads versus explicit language/editor selections               | Existing language SDKs, game tooling, editor integrations and development shells                  | Build representative existing projects with the same sources; verify editor diagnostics              |
| Desktop sessions       | Configured Wayland sessions and explicit Plasma/Jovian selections         | Gaming, accessibility, display behavior, recovery/session choices and host-specific overrides     | Test login, output changes, suspend/resume and application workflows on each owning host             |
| Compute backends       | Ollama, llama-swap, SwarmUI, LM Studio and platform-specific acceleration | Model formats, APIs, image workflows, GPU acceleration and intended concurrency                   | Use identical models/prompts and requests; measure throughput, latency, GPU memory and idle behavior |
| Darwin containers      | Colima versus Docker Desktop, with `none` as the disabled control         | Existing CLI/context behavior, volumes, networking and Homebrew intent                            | Inspect the selected context and VM state, then run a disposable container and networking test       |

## Measurement protocol

1. Pin one source revision and lockfile. Realize the unchanged baseline and one
   narrowly changed candidate on the same native platform. Keep recovery outputs
   and explicit overrides in both. Do not activate candidates merely to measure
   closure size.
2. Compare recursive store-path sets. Sum NAR bytes unique to each closure, and
   report shared bytes separately. A package's own NAR size, package count, or
   module count is not a marginal closure measurement.
3. Run evaluations serially in separate processes, recording wall time and peak
   memory. Separate warm-store runs from cold evaluation-store runs. Keep the
   repository's build concurrency and platform-specific memory policy unchanged.
4. Record build wall time, downloaded bytes, local compilation, and cache state.
   A substituted warm build and a cold source build are different measurements.
5. Run the capability-specific runtime comparison above. Report missing evidence
   before proposing a default change. A smaller closure is not sufficient if a
   workload or recovery path is lost.

Choose a follow-up only after these measurements identify an actual overlap and
its cost. This milestone's evaluation matrix establishes composition coverage;
it does not supply the unbuilt candidate comparisons or runtime benchmarks.
