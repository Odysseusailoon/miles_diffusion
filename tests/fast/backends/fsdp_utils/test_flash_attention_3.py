from tests.ci.ci_register import register_cpu_ci

register_cpu_ci(est_time=15, suite="stage-a-cpu", labels=[])

from types import SimpleNamespace

import torch

from miles.backends.fsdp_utils import flash_attention_3


def test_fa3_calls_follow_torch_deterministic_switch(monkeypatch):
    """A hardcoded flag would pass every GPU repeatability test; the switch must be read per call."""
    recorded = []

    def fake_flash_attn_func(query, key, value, **kwargs):
        recorded.append(("forward", kwargs["deterministic"]))
        lse = torch.zeros(query.shape[0], query.shape[2], query.shape[1])
        return (query, lse) if kwargs["return_attn_probs"] else query

    def fake_flash_attn_backward(*args, deterministic):
        recorded.append(("backward", deterministic))

    monkeypatch.setattr(
        flash_attention_3,
        "flash_attn_interface",
        SimpleNamespace(flash_attn_func=fake_flash_attn_func, _flash_attn_backward=fake_flash_attn_backward),
    )
    q = torch.zeros(1, 2, 8, 4)  # [B, H, S, D], the ring-template layout
    lse = torch.zeros(1, 2, 8)
    try:
        for enabled in (False, True, False):
            torch.use_deterministic_algorithms(enabled)
            flash_attention_3.ring_forward_op(q, q, q, is_causal=False, scale=0.5)
            flash_attention_3.ring_backward_op(
                grad_out=q, query=q, key=q, value=q, out=q, logsumexp=lse, is_causal=False, scale=0.5
            )
    finally:
        torch.use_deterministic_algorithms(False)

    assert recorded == [(phase, enabled) for enabled in (False, True, False) for phase in ("forward", "backward")]
