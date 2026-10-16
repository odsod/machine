# Whisper Server

## Service and Models

- `whisper-server.service` serves OpenAI-compatible `/v1/audio/transcriptions`
  on `127.0.0.1:8178` (ROCm/HIP).
- `whisper_version`, `whisper_model`, `whisper_model_url`, `whisper_vad_model`,
  and `whisper_vad_model_url` live in `mise/conf.d/whisper.toml`.
- Source trees and model weights live in
  `~/.local/share/odsod/machine/data/whisper/`.
- After changing `[vars]`, run `mise run whisper:setup`.

## VRAM Profiles

- **Default (`ggml-large-v3.bin`, 3.1 GB)**: Best Swedish accuracy (32 decoder
  layers).
- **Fallbacks**:
  - `ggml-large-v3-turbo.bin` (1.6 GB, 4 decoder layers, ~1s/clip)
  - `ggml-large-v3-q5_0.bin` (1.1 GB, quantized full model)

## Server Flags

- `--vad` + `--vad-model ggml-silero-v6.2.0.bin`: Server-side Silero VAD filters
  non-speech before decoding (primary hallucination defense).
- `--language auto`: Supports mixed English and Swedish audio.
- `--suppress-nst`: Suppresses non-speech tokens (`[Music]`, `[Applause]`)
  emitted on ambient noise.
- `--convert`: Accepts any audio container without client-side conversion.
- Do not rely on `--no-speech-thold` with `--language auto`; Whisper still emits
  subtitle-credit hallucinations at high no-speech probability.
