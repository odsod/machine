# whisper/

GPU-accelerated speech-to-text server (whisper.cpp + ROCm/HIP).

## VRAM Profiles

Active model is set via `model :=` in the Makefile. After changing, run
`make install-service` and `systemctl --user restart whisper-server`.

| Model | VRAM | Quality | Swedish | Speed |
|-------|------|---------|---------|-------|
| `ggml-large-v3.bin` | 3.1 GB | Best | Good (32 decoder layers) | ~3-4s/clip |
| `ggml-large-v3-turbo.bin` | 1.6 GB | Good | Adequate (4 decoder layers) | ~1s/clip |
| `ggml-large-v3-q5_0.bin` | 1.1 GB | Good | Good (quantized full) | ~3-4s/clip |

**Default**: `ggml-large-v3.bin` (best Swedish quality).
**Fallback**: If VRAM pressure causes desktop stutter, switch to
`ggml-large-v3-turbo.bin` — saves 1.5 GB.

## Download additional models

```bash
make download-model MODEL=ggml-large-v3-turbo.bin
```

## Ports

- `8178` — OpenAI-compatible `/v1/audio/transcriptions`

## OpenWhispr config

- Provider: Custom
- Base URL: `http://localhost:8178` (local) or `http://odsod-desktop:8178` (remote via Tailscale)
