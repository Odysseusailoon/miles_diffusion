from tests.ci.ci_register import register_cuda_ci

register_cuda_ci(
    est_time=60,
    suite="stage-b-3-gpu-h200",
    labels=["fsdp"],
)

import os
import sys

# deterministic mode needs this before the first cuBLAS call (see docs/advanced/deterministic.md)
os.environ.setdefault("CUBLAS_WORKSPACE_CONFIG", ":4096:8")

import pytest
import torch
import torch.nn.functional as F

from miles.backends.fsdp_utils import flash_attention_3

# Long enough for FA3's default (atomic-add) dQ accumulation to be visibly order-dependent.
SHAPE = (1, 8192, 8, 128)  # [batch, sequence, heads, head dim]


def _inputs(seed=0):
    generator = torch.Generator(device="cuda").manual_seed(seed)
    tensors = [torch.randn(SHAPE, device="cuda", dtype=torch.bfloat16, generator=generator) for _ in range(4)]
    query, key, value, grad_output = tensors
    return query.requires_grad_(True), key.requires_grad_(True), value.requires_grad_(True), grad_output


def _dispatch_flash3(query, key, value):
    from diffusers.models.attention_dispatch import dispatch_attention_fn

    return dispatch_attention_fn(query, key, value, backend="_flash_3")


def _forward_backward(attention, query, key, value, grad_output):
    query.grad = key.grad = value.grad = None
    output = attention(query, key, value)
    output.backward(grad_output)
    return output.detach(), query.grad.clone(), key.grad.clone(), value.grad.clone()


def test_diffusers_flash3_backend_is_differentiable_and_matches_sdpa():
    """Upstream's custom op has no backward; ours must, and agree with SDPA."""
    flash_attention_3.install_diffusers_backend()
    query, key, value, grad_output = _inputs()

    def sdpa(q, k, v):
        return F.scaled_dot_product_attention(q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)).transpose(1, 2)

    got = _forward_backward(_dispatch_flash3, query, key, value, grad_output)
    want = _forward_backward(sdpa, query, key, value, grad_output)
    for name, g, w in zip(("out", "dQ", "dK", "dV"), got, want, strict=True):
        torch.testing.assert_close(g, w, rtol=2e-2, atol=2e-2, msg=lambda m, _name=name: f"{_name}: {m}")


def test_diffusers_flash3_backend_follows_torch_deterministic_mode():
    """FA3's default dQ accumulation is order-dependent; torch's flag must reach the kernel at call time."""
    flash_attention_3.install_diffusers_backend()
    query, key, value, grad_output = _inputs()
    torch.use_deterministic_algorithms(True, warn_only=False)
    try:
        first = _forward_backward(_dispatch_flash3, query, key, value, grad_output)
        second = _forward_backward(_dispatch_flash3, query, key, value, grad_output)
    finally:
        torch.use_deterministic_algorithms(False)
    for name, a, b in zip(("out", "dQ", "dK", "dV"), first, second, strict=True):
        assert torch.equal(a, b), f"{name} differs between two deterministic FA3 runs"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
