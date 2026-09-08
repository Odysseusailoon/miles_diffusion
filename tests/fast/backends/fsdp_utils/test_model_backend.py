from tests.ci.ci_register import register_cpu_ci

register_cpu_ci(est_time=15, suite="stage-a-cpu", labels=[])

import torch

from miles.backends.fsdp_utils.model_backend import BaseModelBackend, DiffusersModelBackend, MilesModelBackend
from miles.backends.fsdp_utils.models.diffusers import load_fsdp_parallel_plan


class _RecordingModel(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.selected = None
        self.gradient_checkpointing_enabled = False
        self._no_split_modules = ["TransformerBlock"]

    def set_attention_backend(self, backend):  # diffusers protocol method
        self.selected = backend

    def enable_gradient_checkpointing(self):
        self.gradient_checkpointing_enabled = True


class TestBackendHierarchy:
    def test_concrete_backends_are_sibling_implementations(self):
        assert issubclass(MilesModelBackend, BaseModelBackend)
        assert issubclass(DiffusersModelBackend, BaseModelBackend)
        assert not issubclass(DiffusersModelBackend, MilesModelBackend)

    def test_diffusers_implements_model_lifecycle_hooks(self):
        backend = DiffusersModelBackend(None)
        model = _RecordingModel()

        backend.enable_gradient_checkpointing(model)
        backend.set_attention_backend(model, "flash")
        plan = backend.fsdp_parallel_plan(model)

        assert model.gradient_checkpointing_enabled
        assert model.selected == "flash"
        assert plan.no_split_modules == ("TransformerBlock",)
        assert plan.param_dtype_patterns == {}

    def test_diffusers_binds_flash3_only_when_selected(self, monkeypatch):
        """Selecting `_flash_3` must install the trainer's binding before diffusers dispatches to it."""
        from miles.backends.fsdp_utils import flash_attention_3

        installs = []
        monkeypatch.setattr(flash_attention_3, "install_diffusers_backend", lambda: installs.append("_flash_3"))
        backend = DiffusersModelBackend(None)
        model = _RecordingModel()

        backend.set_attention_backend(model, "_flash_3")
        assert installs == ["_flash_3"]
        assert model.selected == "_flash_3"

        backend.set_attention_backend(model, "native")
        assert installs == ["_flash_3"]

    def test_all_diffusers_model_plans_load(self):
        assert load_fsdp_parallel_plan("sd3").param_dtype_patterns == {}
        assert load_fsdp_parallel_plan("qwen_image").param_dtype_patterns == {}
        assert load_fsdp_parallel_plan("wan2_2").param_dtype_patterns
