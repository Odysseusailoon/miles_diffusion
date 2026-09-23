# Dense FA3 training and pure Ulysses validation

This regression targets `DiffusersModelBackend`, the `_flash_3` backend, and
Miles pure Ulysses (`ring_degree=1`). It exercises real FA3 without downloading
model weights. Passing it establishes attention-level correctness on the tested
hardware/build/shapes, not full-model, FSDP2, or rollout/train equivalence.

## Why the adapter exists

At the Diffusers pin in `requirements.txt`
(`f53d552036a0d1bd5570782a39cd40cfabf112bc`), `_flash_attention_3` filters out
`deterministic` and calls a forward-only custom op. That op passes an explicit
`deterministic=False`, overriding a `functools.partial(..., deterministic=True)`
default. An inner autograd-capable function does not provide an autograd formula
for the outer custom op.

`miles/backends/fsdp_utils/fa3_attention.py` registers an adapter that calls the
public FA3 autograd function directly, with `num_splits=1`. The registry decorator
also refreshes the cached accepted argument names. Both deterministic-on and
deterministic-off explicit `_flash_3` selection use the adapter. Forced actor mode
or PyTorch deterministic mode takes precedence over a per-call false value.
With deterministic mode enabled and the CLI backend unset, the model backend
resolves Diffusers' active backend, including environment-based selection.

Only the selected kernel can satisfy driver validation: installed FA2 cannot
validate FA3. Hub and varlen FA3 paths have no integration here. Native model
spellings such as LTX `flash_attention_3` retain their separate package hook.

The registry is process-wide. Install before execution/compilation; separate
processes are required for models needing different forced modes. Masks,
nonzero dropout, split counts other than one, and Diffusers context-parallel
configurations are rejected. Miles Ulysses moves tensors before the local call
and clears that configuration. Ring remains unsupported. Optional LSE has
Diffusers' `[B,S,H]` layout and is detached: upstream FA3 does not differentiate it.

## Environment and preflight

Use the project's complete GPU image, with its matching PyTorch/CUDA/FA3 wheel.
The worker requires SM80 or newer and actual support in the installed FA3 build.
The Miles cu129 wheel's associated source includes SM80 forward/backward; do not
reject A800 solely because it is not Hopper. Successful SM80 execution does not
establish deterministic backward or validate the separate Hopper implementation.
`fsdp_utils` currently imports the train actor eagerly, so a minimal installation
of only Torch, Diffusers and FA3 is insufficient for normal Miles imports.
Do not rebuild the full image or download a model as the first experiment.

Record the Miles commit, image digest, driver, CUDA, NCCL, Python, PyTorch,
Diffusers commit, FA3 wheel filename/hash, actual `flash_attn_interface.__file__`,
SGLang commit, GPU topology, commands, seeds and results. Docker's SGLang branch
is not an immutable pin; record the commit actually installed.

From the checkout root:

```bash
mkdir -p artifacts/fa3
git rev-parse HEAD > artifacts/fa3/miles-commit.txt
python -m pip freeze > artifacts/fa3/packages.txt
nvidia-smi > artifacts/fa3/nvidia-smi.txt
nvidia-smi topo -m > artifacts/fa3/topology.txt
python - <<'PY'
import inspect
import torch
import flash_attn_interface as fa3
import diffusers.models.attention_dispatch as ad
print('torch/cuda:', torch.__version__, torch.version.cuda)
print('kernel file:', fa3.__file__)
print('kernel signature:', inspect.signature(fa3.flash_attn_func))
assert callable(ad.flash_attn_3_func), 'Diffusers did not load FA3'
assert torch.cuda.get_device_capability()[0] >= 8, 'Expected SM80 or newer'
print('Diffusers kernel:', ad.flash_attn_3_func)
PY
```

If imports fail, stop and fix the image before running more ranks. Do not replace
FA3 with SDPA or mark an unavailable-kernel result as passing.

## CPU interface regression

In the complete development/CI environment:

```bash
python -m pytest -q \
  tests/fast/backends/test_fsdp_deterministic_args.py \
  tests/fast/backends/fsdp_utils/test_model_backend.py \
  tests/fast/backends/fsdp_utils/test_fa3_attention.py
```

These use real Diffusers dispatch and Torch autograd with a differentiable CPU
kernel spy. They establish argument routing and graph preservation, not CUDA
kernel behavior. They also cover the actor's enable-before-set order, active
backend selection, registry isolation, mode-off behavior and detached LSE.

## GPU gates: stop at the first failure

First run one GPU, using a small input. `timeout` below is GNU coreutils on Linux.
The worker's process-group timeout is an additional protection against hangs.

```bash
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"
export CUBLAS_WORKSPACE_CONFIG=:4096:8
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export PYTHONUNBUFFERED=1
timeout --kill-after=10s 300s python -m torch.distributed.run --standalone --nnodes=1 --nproc_per_node=1 \
  tests/fast-gpu/backends/fsdp_utils/sequence_parallel/_fa3_attention_worker.py \
  --seq-len 128 --repeats 20 --output-json artifacts/fa3/bf16-sp1.json \
  > artifacts/fa3/bf16-sp1.log 2>&1
```

On SM80, immediately repeat the single-GPU test with `--seq-len 1024` and
`--repeats 30`. Multiple key tiles must contribute to dQ; a short sequence can
hide unordered backward accumulation. Stop and isolate upstream FA3 if exact
repeatability fails, even when every value is numerically close.

Only after these pass, repeat with `--nproc_per_node=2`, then `4`, and distinct
`bf16-sp2` / `bf16-sp4` output filenames. Keep seed, full sequence length, batch,
head count and head dimension unchanged. All cases compare their local shards
against a full-sequence FA3 reference and independent FP32 math SDPA. No model or
Ray service needs to be launched.

Next exercise a longer shape and a second dtype:

```bash
timeout --kill-after=10s 300s python -m torch.distributed.run --standalone --nnodes=1 --nproc_per_node=2 \
  tests/fast-gpu/backends/fsdp_utils/sequence_parallel/_fa3_attention_worker.py \
  --seq-len 1024 --head-dim 128 --repeats 20 \
  --output-json artifacts/fa3/bf16-sp2-long.json \
  > artifacts/fa3/bf16-sp2-long.log 2>&1
timeout --kill-after=10s 300s python -m torch.distributed.run --standalone --nnodes=1 --nproc_per_node=1 \
  tests/fast-gpu/backends/fsdp_utils/sequence_parallel/_fa3_attention_worker.py \
  --dtype float16 --repeats 20 --output-json artifacts/fa3/fp16-sp1.json \
  > artifacts/fa3/fp16-sp1.log 2>&1
```

These shapes are initial probes; add the actual target model's head dimensions
and sequence lengths after confirming the small cases. Long-video shapes can
make the independent math reference expensive, so increase sizes deliberately.

The strict CI grid (BF16 SP1/2/4, FP16 SP1; S=1024 and 20 repeats) is:

```bash
python -m pytest -q tests/fast-gpu/backends/fsdp_utils/sequence_parallel/test_fa3_attention.py
```

It requires four visible GPUs. On a one-GPU host select `-k sp1`; on a two-GPU
host select `-k 'not sp4'`. Report the omitted topology as untested. CPU skips
are not GPU passes. CUDA CI fails when devices or FA3 are missing.

## Acceptance and evidence

- The spy sees real FA3, `num_splits=1`, and the requested deterministic mode;
  no fallback path can satisfy the test.
- Output and dQ/dK/dV are finite and match both references within logged bounds.
- Repeating fixed inputs/topology gives bitwise-equal output and dQ/dK/dV in
  deterministic mode. Compare repeats within one topology, not bitwise across SP.
- A tiny shared QKV projection matches the full-sequence loss, summed parameter
  gradient and one SGD update. This uses explicit gradient summation, not FSDP2.
- Mode-off forward/backward also matches its direct FA3 reference; mode-off is
  not required to show nondeterminism.

Initial cross-reference bounds are `rtol=2*eps(dtype)`, `atol=eps(dtype)/16`.
They are proposed test bounds, not measured GPU results. Do not widen them to
turn a failure green. Save error magnitudes, input shape and installed versions;
investigate scale, reduction order, layout and kernel choice first. Same-topology
repeat equality has zero tolerance.

The worker writes aggregate mismatch counts, errors, timings, memory and kernel
calls to JSON, plus rank-specific failure JSON. Preserve logs and exit codes.
Its time is total validation runtime, not an attention throughput benchmark.
Run the gates in a fresh process again to check restart reproducibility as needed;
this worker checks bitwise repeats within each process, not persisted cross-run
tensor hashes.

## Observed SM80 limitation (2026-09-23)

The cu129 `flash_attn_3-3.0.0b1-cp39-abi3-linux_x86_64.whl` from
`yueming-yuan/miles-wheels`, SHA256
`b0f4d97418aa129522cd4b4e65ce516ddf8af64815f4ce040cb38a6d94cef971`,
executes on A800 with Torch 2.11.0+cu129 and driver 570.158.01. Its interface
matches FlashAttention source revision `fbf24f67`.

For fixed inputs B=2, S=1024, H=8, D=64, noncausal attention and
`deterministic=True, num_splits=1`, a standalone call to the upstream public
function failed exact dQ repeatability in all 19 comparisons against the first
run, for both BF16 and FP16. Output, dK and dV remained bitwise equal and finite.
Maximum observed dQ differences were 0.0009765625 (BF16) and 0.0001220703125
(FP16). The standalone reproducer does not import Miles or Diffusers.

Miles' S=128 BF16 smoke passed on SP1/2/4, including the tiny projection update.
That is insufficient evidence of deterministic training: short sequences can
hide multi-tile accumulation. This finding is why the strict regression uses
S=1024. The adapter repairs dispatch and preserves autograd; it cannot impose a
deterministic reduction order on an upstream kernel that ignores that contract.

**Strict deterministic SM80 support is incomplete for this tested build.** Do
not weaken the equality assertion or describe the PR as fully validated. A
production deterministic guarantee requires an upstream fix/validated build or
a targeted rejection of the unsupported deterministic-training configuration.
This does not mean all FA3 versions fail on SM80. The SM80 result alone cannot
establish Hopper behavior. Ring and full-model behavior remain separate scopes.

The associated [SM80 backward source](https://github.com/Dao-AILab/flash-attention/blob/fbf24f67cf7f6442c5cfb2c1057f4bfc57e72d89/hopper/mainloop_bwd_sm80.hpp#L833)
uses unordered dQ atomic additions. That is a plausible explanation for the
measurement, not independent proof of the binary's exact build configuration.

## H100 comparison (2026-09-23)

The same source archive, Python 3.13.5, Torch 2.11.0+cu129, pinned Diffusers
wheel, FA3 wheel above, seeds and explicit tensor shapes were rerun on H100
(SM90, driver 595.91.07). Standalone BF16 and FP16 S=1024 passed all 19 repeated
comparisons for output, dQ, dK and dV. Miles BF16 SP1/2/4 and FP16 SP1 passed at
both S=128 and S=1024, with 20 runs each. Every Miles case completed 91 checks,
including numerical references, bitwise repeats, a projection SGD update and
deterministic-off backward. The four-GPU SDPA control and 48 focused CPU tests
also passed.

These runs used the real operators with only the eager actor package initializer
bypassed. They establish the measured H100 attention behavior, not successful
import of the complete actor, rollout/training equivalence, performance, or
bitwise equality across GPU architectures. The A800 limitation remains.

## Remaining rollout and model gate

This patch changes the Diffusers training adapter. SGLang diffusion rollout has a
separate attention implementation. A rollout flag or the name "FA3" alone does
not establish that both sides executed compatible kernels.

Before claiming end-to-end support, agree on the model, checkpoint revision,
container, attention backend and pure-Ulysses topology. Then:

1. Instrument the actual SGLang diffusion attention call. Verify FA3/`fa_ver=3`,
   input layout, dtype, scale, mask, sequence lengths and split count. Its varlen
   inference interface differs from the dense training autograd interface.
2. With frozen weights, capture one attention layer's Q/K/V after positional
   transforms. Replay identical tensors through rollout and training entrypoints;
   use numerical parity, not an assumption of bitwise equality between kernels.
3. Replay identical latents, timesteps and conditioning through the frozen
   transformer. Compare predictions and the log-probability quantity actually
   used by the selected Miles objective.
4. Run one actual FSDP2 update and weight synchronization. Check parameter/LoRA
   synchronization and finite losses/gradients before a short training smoke.

Native LTX, hub/varlen training backends, ring, compile/CUDA graphs, arbitrary
masks/GQA, and full-model repeatability are separate validation scopes. Do not
claim them from this attention-level test.
