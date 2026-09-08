"""Trainer-owned FlashAttention-3 binding.

diffusers' ``_flash_3`` backend is a torch custom op with no autograd formula and a
hardcoded ``deterministic=False``, so the trainer binds ``flash_attn_interface`` itself
for the model's attention processors and for torch's ring templates under USP. The
backward follows ``torch.use_deterministic_algorithms`` like the native kernels do.
"""

import torch

try:
    import flash_attn_interface
except (ImportError, OSError, RuntimeError):  # same loader failures diffusers treats as "not installed"
    flash_attn_interface = None


def is_available() -> bool:
    return flash_attn_interface is not None


def _flash_attn_interface():
    if flash_attn_interface is None:
        raise RuntimeError("FlashAttention-3 (flash_attn_interface) is not installed")
    return flash_attn_interface


def flash3_attention(query, key, value, *, scale=None, causal=False, return_lse=False):
    """Differentiable FA3 on [B, S, H, D] tensors; ``return_lse`` adds the [B, H, S] row logsumexp."""
    return _flash_attn_interface().flash_attn_func(
        query,
        key,
        value,
        softmax_scale=scale,
        causal=causal,
        deterministic=torch.are_deterministic_algorithms_enabled(),
        return_attn_probs=return_lse,
    )


def ring_forward_op(query, key, value, *, is_causal, scale):
    """One KV step of torch's ring template: [B, H, S, D] in, (out [B, H, S, D], lse [B, H, S]) out."""
    out, lse = flash3_attention(
        query.transpose(1, 2),
        key.transpose(1, 2),
        value.transpose(1, 2),
        scale=scale,
        causal=is_causal,
        return_lse=True,
    )
    return out.transpose(1, 2), lse


def ring_backward_op(*, grad_out, query, key, value, out, logsumexp, is_causal, scale):
    """One KV step of torch's ring backward; ``out``/``logsumexp`` are the ring-merged results."""
    query_bshd, key_bshd, value_bshd, out_bshd, grad_out_bshd = (
        t.transpose(1, 2).contiguous() for t in (query, key, value, out, grad_out)
    )
    grad_query = torch.empty_like(query_bshd)
    grad_key = torch.empty_like(key_bshd)
    grad_value = torch.empty_like(value_bshd)
    # positional layout of FlashAttnFunc.backward; the six None slots are the varlen arguments
    _flash_attn_interface()._flash_attn_backward(
        grad_out_bshd,
        query_bshd,
        key_bshd,
        value_bshd,
        out_bshd,
        logsumexp.contiguous(),
        None,
        None,
        None,
        None,
        None,
        None,
        grad_query,
        grad_key,
        grad_value,
        scale,
        is_causal,
        deterministic=torch.are_deterministic_algorithms_enabled(),
    )
    return grad_query.transpose(1, 2), grad_key.transpose(1, 2), grad_value.transpose(1, 2)


def _diffusers_flash_attention_3(
    query,
    key,
    value,
    attn_mask=None,
    scale=None,
    is_causal=False,
    return_lse=False,
    _parallel_config=None,
):
    if attn_mask is not None:
        raise ValueError("`attn_mask` is not supported for flash-attn 3.")
    result = flash3_attention(query, key, value, scale=scale, causal=is_causal, return_lse=return_lse)
    if not return_lse:
        return result
    out, lse = result
    return out, lse.permute(0, 2, 1)  # diffusers returns lse as [B, S, H]


def install_diffusers_backend() -> None:
    """Re-register diffusers' ``_flash_3`` backend on this binding, keeping upstream's input constraints."""
    import diffusers.models.attention_dispatch as ad

    _flash_attn_interface()
    name = ad.AttentionBackendName._FLASH_3
    registry = ad._AttentionBackendRegistry
    registry.register(name, constraints=registry._constraints[name])(_diffusers_flash_attention_3)
