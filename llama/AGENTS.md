# Llama Server

## Service and Models

- `llama-server.service` serves OpenAI-compatible `/v1/chat/completions` on
  `127.0.0.1:8179` (ROCm/HIP on the desktop Radeon RX 9060 XT, 16 GB VRAM).
- `llama_version`, `llama_model`, and `llama_model_url` live in
  `mise/conf.d/llama.toml`.
- Source trees and GGUF weights live in `~/.local/share/odsod/machine/data/llama/`.
- After changing `[vars]`, run `mise run llama:setup`.

## VRAM Profiles

- **Default (`Qwen3.5-9B-Q5_K_M.gguf`, 6.3 GB)**: Best quality-to-VRAM ratio
  (~15.4 GB total with `whisper-server` `large-v3`, 32k KV cache, and desktop).
- **Fallbacks if VRAM pressure causes desktop stutter**:
  - `Qwen3.5-9B-Q4_K_M.gguf` (5.4 GB, saves ~0.9 GB)
  - `Qwen3-8B-Q4_K_M.gguf` (5.0 GB, saves ~1.3 GB)
