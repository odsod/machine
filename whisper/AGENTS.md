# whisper/

GPU-accelerated speech-to-text server (whisper.cpp + ROCm/HIP).

## VRAM Profiles

Active model is set via `model :=` in the Makefile. After changing, run
`make install-service` and `systemctl --user restart whisper-server`.

| Model                     | VRAM   | Quality | Swedish                     | Speed      |
| ------------------------- | ------ | ------- | --------------------------- | ---------- |
| `ggml-large-v3.bin`       | 3.1 GB | Best    | Good (32 decoder layers)    | ~3-4s/clip |
| `ggml-large-v3-turbo.bin` | 1.6 GB | Good    | Adequate (4 decoder layers) | ~1s/clip   |
| `ggml-large-v3-q5_0.bin`  | 1.1 GB | Good    | Good (quantized full)       | ~3-4s/clip |

**Default**: `ggml-large-v3.bin` (best Swedish quality).
**Fallback**: If VRAM pressure causes desktop stutter, switch to
`ggml-large-v3-turbo.bin` — saves 1.5 GB.

## Download additional models

```bash
make download-model MODEL=ggml-large-v3-turbo.bin
```

## Server Flags

| Flag              | Value                    | Rationale                                                                                                                                                                        |
| ----------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--vad`           | enabled                  | Server-side Silero VAD — primary hallucination defense. Skips non-speech before decoding. Industry-grade spectral analysis (0.97 accuracy) vs our coarse RMS gate                |
| `--vad-model`     | `ggml-silero-v5.1.2.bin` | GGML-format Silero VAD from `huggingface.co/ggml-org/whisper-vad`                                                                                                                |
| `--language auto` | auto                     | Meetings mix English + Swedish; forcing one degrades the other                                                                                                                   |
| `--suppress-nst`  | enabled                  | Suppresses non-speech tokens (`[Music]`, `[Applause]`, brackets) during decoding. Whisper was trained on subtitled video and emits these on ambient noise. See whisper.cpp #1724 |
| `--convert`       | enabled                  | Accepts any audio format (WAV, etc.) without external conversion                                                                                                                 |

### Flags evaluated and not used

- `--no-speech-thold` (default 0.6): Does not help when `--language auto` is set — whisper confidently
  emits training artifacts (subtitle credits) even with high no-speech probability because the model
  was trained on subtitled video data. See whisper.cpp PR #3763.

### VAD architecture note

Client-side RMS gating is kept but permissive (threshold 0.002) — its role is to avoid
sending dead-silence WAVs over HTTP. The real speech/non-speech decision is made by
server-side Silero VAD. Previous attempt at client-side Silero failed because it needed
mic gain boost to trigger reliably; server-side is different since it processes audio that
already passed through parec capture.

## Ports

- `8178` — OpenAI-compatible `/v1/audio/transcriptions`

## OpenWhispr config

- Provider: Custom
- Base URL: `http://localhost:8178` (local) or `http://odsod-desktop:8178` (remote via Tailscale)
