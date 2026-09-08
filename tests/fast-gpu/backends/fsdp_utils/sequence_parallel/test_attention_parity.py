from tests.ci.ci_register import register_cuda_ci

register_cuda_ci(
    est_time=360,
    suite="stage-c-5-gpu-h200",
    labels=["fsdp"],
)

import os
import subprocess
import sys
from pathlib import Path

import pytest


_WORKER = Path(__file__).with_name("_attention_parity_worker.py")


def _run_worker(ulysses_degree, *, deterministic=False, attention_backend=None):
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    command = [
        sys.executable,
        "-m",
        "torch.distributed.run",
        "--standalone",
        "--nnodes=1",
        "--nproc_per_node=4",
        str(_WORKER),
        "--ulysses-degree",
        str(ulysses_degree),
    ]
    if attention_backend is not None:
        command += ["--attention-backend", attention_backend]
    if deterministic:
        env["CUBLAS_WORKSPACE_CONFIG"] = ":4096:8"
        # long enough that each ring shard spans several FA3 backward tiles
        command += ["--deterministic", "--sequence-length", "8192"]
    subprocess.run(
        command,
        check=True,
        env=env,
    )


@pytest.mark.parametrize(
    ("ulysses_degree", "attention_backend"),
    [
        (4, None),
        (2, None),
        (1, None),
        (2, "_native_cudnn"),
        (1, "_native_cudnn"),
        (4, "_flash_3"),
        (2, "_flash_3"),
        (1, "_flash_3"),
    ],
    ids=[
        "sp4-u4r1",
        "sp4-u2r2",
        "sp4-u1r4",
        "sp4-u2r2-cudnn",
        "sp4-u1r4-cudnn",
        "sp4-u4r1-fa3",
        "sp4-u2r2-fa3",
        "sp4-u1r4-fa3",
    ],
)
def test_usp_forward_backward_matches_full_sequence_attention(ulysses_degree, attention_backend):
    _run_worker(ulysses_degree, attention_backend=attention_backend)


@pytest.mark.parametrize(
    ("ulysses_degree", "attention_backend"),
    [
        (4, None),
        (2, None),
        (1, None),
        (4, "_flash_3"),
        (2, "_flash_3"),
        (1, "_flash_3"),
    ],
    ids=["sp4-u4r1", "sp4-u2r2", "sp4-u1r4", "sp4-u4r1-fa3", "sp4-u2r2-fa3", "sp4-u1r4-fa3"],
)
def test_usp_forward_backward_is_bitwise_repeatable_in_deterministic_mode(ulysses_degree, attention_backend):
    _run_worker(ulysses_degree, deterministic=True, attention_backend=attention_backend)


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
