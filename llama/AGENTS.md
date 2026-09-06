# llama/

GPU-accelerated LLM inference server (llama.cpp + ROCm/HIP).

## VRAM Profiles

Active model is set via `MODEL` in `tasks/setup-llama.sh` and `model` in
`llama/mise.toml` `[vars]`. After changing, run `mise run setup:llama` and
`systemctl --user restart llama-server`.

| Model                    | VRAM   | Quality | Swedish        | Speed |
| ------------------------ | ------ | ------- | -------------- | ----- |
| `Qwen3.5-9B-Q5_K_M.gguf` | 6.3 GB | High    | 201 languages  | Fast  |
| `Qwen3.5-9B-Q4_K_M.gguf` | 5.4 GB | Good    | 201 languages  | Fast  |
| `Qwen3-8B-Q4_K_M.gguf`   | 5.0 GB | Good    | 100+ languages | Fast  |

**Default**: `Qwen3.5-9B-Q5_K_M.gguf` (best quality-to-VRAM ratio).
**Fallback**: If VRAM pressure causes desktop stutter, switch to
`Qwen3.5-9B-Q4_K_M.gguf` — saves ~0.9 GB. Or drop to
`Qwen3-8B-Q4_K_M.gguf` — saves ~1.3 GB total.

## Download additional models

```bash
# Latest tag:
mise run -C llama discover
# Extra GGUF into ~/.local/share/odsod/machine/data/llama/:
curl -fL -o ~/.local/share/odsod/machine/data/llama/Qwen3.5-9B-Q4_K_M.gguf \
  https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf
```

## Ports

- `8179`: OpenAI-compatible `/v1/chat/completions` (chat model)

## OpenWhispr config

- LLMs > Dictation Cleanup: Custom provider
- Base URL: `http://localhost:8179` (local) or `http://odsod-desktop:8179` (remote via Tailscale)

## VRAM Budget (RX 9060 XT, 16 GB total)

### High-spec (default)

| Component                    | VRAM         |
| ---------------------------- | ------------ |
| whisper-server (large-v3)    | 3.1 GB       |
| llama-server (Qwen3.5-9B Q5) | 6.3 GB       |
| KV cache (32k chat)          | ~3 GB        |
| Desktop/browsers             | ~3 GB        |
| **Total**                    | **~15.4 GB** |

### Low-spec (fallback if VRAM-constrained)

| Component                       | VRAM         |
| ------------------------------- | ------------ |
| whisper-server (large-v3-turbo) | 1.6 GB       |
| llama-server (Qwen3-8B Q4)      | 5.0 GB       |
| KV cache (32k chat)             | ~2 GB        |
| Desktop/browsers                | ~3 GB        |
| **Total**                       | **~11.6 GB** |

If desktop apps stutter during inference, switch to the low-spec models.
The AMD GPU driver pages inactive VRAM to system RAM (GTT) under pressure,
so the system won't crash, but inference latency increases when pages are
evicted and reloaded.

## Roadmap

### Move display to Intel iGPU

- **Goal**: Eliminate display/inference VRAM contention entirely
- **How**: Plug monitors into motherboard video outputs, enable iGPU multi-display in BIOS
- **Effect**: Desktop compositor + browser use shared system RAM via Intel UHD 770 (renderD128), dGPU becomes inference-only
- **Saves**: ~1.5 GB VRAM on dGPU (no compositor/browser textures)
- **Trade-off**: Intel RPL-S GT1 lacks H.264/HEVC VA-API decode (only JPEG/VP9/MPEG2). YouTube (VP9) still hardware-decodes; other video software-decodes or needs explicit routing to dGPU VA-API
- **Prerequisite**: Physical cable swap + BIOS change

### Quantized KV cache for chat model

- **Goal**: Halve KV cache VRAM usage
- **How**: Add `-ctk q8_0 -ctv q8_0` to `llama-server.service`
- **Effect**: KV cache uses 8-bit instead of f16
- **Saves**: ~600 MB VRAM
- **Trade-off**: Negligible quality loss on a 9B model

### Explicit flash attention

- **Goal**: Ensure flash attention is always enabled
- **How**: Add `--flash-attn on` to `llama-server.service`
- **Effect**: More memory-efficient attention computation, reduced KV cache footprint
- **Trade-off**: None (likely already auto-enabled, this makes it explicit)
