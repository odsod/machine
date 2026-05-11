# llama/

GPU-accelerated LLM inference server (llama.cpp + ROCm/HIP).

## VRAM Profiles

Active model is set via `model :=` in the Makefile. After changing, run
`make install-service` and `systemctl --user restart llama-server`.

| Model | VRAM | Quality | Swedish | Speed |
|-------|------|---------|---------|-------|
| `Qwen3.5-9B-Q5_K_M.gguf` | 6.3 GB | High | 201 languages | Fast |
| `Qwen3.5-9B-Q4_K_M.gguf` | 5.4 GB | Good | 201 languages | Fast |
| `Qwen3-8B-Q4_K_M.gguf` | 5.0 GB | Good | 100+ languages | Fast |

**Default**: `Qwen3.5-9B-Q5_K_M.gguf` (best quality-to-VRAM ratio).
**Fallback**: If VRAM pressure causes desktop stutter, switch to
`Qwen3.5-9B-Q4_K_M.gguf` — saves ~0.9 GB. Or drop to
`Qwen3-8B-Q4_K_M.gguf` — saves ~1.3 GB total.

## Download additional models

```bash
make download-model URL=https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf
```

## Ports

- `8179` — OpenAI-compatible `/v1/chat/completions`

## OpenWhispr config

- LLMs > Dictation Cleanup: Custom provider
- Base URL: `http://localhost:8179` (local) or `http://odsod-desktop:8179` (remote via Tailscale)

## VRAM Budget (RX 9060 XT, 16 GB total)

### High-spec (default)

| Component | VRAM |
|-----------|------|
| whisper-server (large-v3) | 3.1 GB |
| llama-server (Qwen3.5-9B Q5) | 6.3 GB |
| KV cache + overhead | ~1.5 GB |
| Desktop/browsers | ~4 GB |
| **Total** | **~14.9 GB** |

### Low-spec (fallback if VRAM-constrained)

| Component | VRAM |
|-----------|------|
| whisper-server (large-v3-turbo) | 1.6 GB |
| llama-server (Qwen3-8B Q4) | 5.0 GB |
| KV cache + overhead | ~1 GB |
| Desktop/browsers | ~4 GB |
| **Total** | **~11.6 GB** |

If desktop apps stutter during inference, switch to the low-spec models.
The AMD GPU driver pages inactive VRAM to system RAM (GTT) under pressure,
so the system won't crash — but inference latency increases when pages are
evicted and reloaded.
