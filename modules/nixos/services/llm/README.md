# Local model memory

On `khanelinix`, llama-swap owns the Qwen agent models and Colibri. Ollama
stores the downloaded weights and serves the remaining models. These managers do
not coordinate GPU memory with each other or with desktop applications.

## Switch GPU workloads

On an AMD host with ROCm and both model servers enabled, set
`khanelinix.services.llm.gpuCoordination.enable = true` to install `llm-gpu`.
Both servers must listen on loopback or a wildcard address. The helper connects
over loopback on their configured ports and does nothing at startup.

```sh
llm-gpu status
llm-gpu llama-swap       # Preview unloading Ollama models
llm-gpu ollama          # Preview unloading llama-swap models
llm-gpu desktop         # Preview unloading both sets of models
llm-gpu desktop --apply
```

Wait for active requests to finish before applying a switch. The helper only
unloads models; it does not stop services, delete weights, load a target model,
or prevent another client from loading one. Check `llm-gpu status` and
`amdgpu_top` before starting the next workload: an unload response does not mean
the GPU has released the memory yet.

OpenCode and Pi read the model IDs and endpoint from the configured llama-swap
service. Set `displayName` on a model to show a label instead of its ID.
`maxOutputTokens` advertises an optional client limit without changing the
server. OpenCode needs both the context and output limit to set its model
limits; Pi can accept either independently.

## Check residency and competing applications

```sh
ollama ps
curl --fail --silent --show-error http://127.0.0.1:8090/running
free -h
ps -eo pid,comm,rss --sort=-rss | head -n 20
nvtop
```

`ollama list` lists installed weights, not loaded models. In `free`, use
`available` to assess headroom; Linux can reclaim much of the filesystem cache.
The process list reports RSS in KiB, including shared mappings. Do not sum RSS
as if each process owned every page exclusively.

For a machine-readable AMD GPU snapshot:

```sh
amdgpu_top -p -J -n 1
```

This reports per-process VRAM and GTT, which is GPU-accessible system memory.
Shared buffers and driver allocations mean per-process totals need not equal
device usage. Process visibility also depends on permissions.

Save work and close unused GPU applications through their normal UI before
loading a large model. Do not kill the compositor or lock screen to reclaim
VRAM. Avoid dropping filesystem caches or forcing swap back into RAM: neither is
a substitute for unloading a model, and both can make the next load slower.

## Unload models

Wait for active requests to finish before manually unloading their model.
Unloading releases runtime memory; it does not delete downloaded weights.

For an Ollama model, use the name from `ollama ps`:

```sh
ollama stop MODEL
```

For llama-swap, unload every running model, including Colibri:

```sh
curl --fail --silent --show-error --request POST \
  http://127.0.0.1:8090/api/models/unload
```

To unload only the coding model:

```sh
curl --fail --silent --show-error --request POST \
  http://127.0.0.1:8090/api/models/unload/qwen3-coder-30b
```

The [llama-swap UI](http://127.0.0.1:8090/ui) also provides load and unload
controls. Check residency and GPU memory again after unloading; memory release
can lag the HTTP acknowledgement.

## Automatic unloading

- Ollama defaults to 60 seconds idle through `OLLAMA_KEEP_ALIVE`. A client's
  `keep_alive` value overrides that default. API callers can use `keep_alive: 0`
  to unload after their response.
- Each llama-swap model has a 300-second inactivity timeout unless overridden by
  its `ttl`. A zero TTL keeps the model resident.
- Colibri uses the same llama-swap timeout. Its expert cache budget is not a cap
  on total process VRAM or RAM.

Shorter timeouts recover memory sooner but introduce more cold loads. Keep five
minutes for interactive editing bursts, and unload explicitly before switching
to another GPU-heavy application or the other model manager.

## Speech recognition

Voxtype's Parakeet engine also retains a model. Its native
`parakeet.on_demand_loading` option can trade recording startup latency for
lower idle RAM use. Validate it with the configured streaming mode before
changing it; stopping Voxtype also disables dictation.

References: [Ollama memory management](https://docs.ollama.com/faq),
[llama-swap controls](https://github.com/mostlygeek/llama-swap).
