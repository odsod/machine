import tomllib
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class AudioConfig:
    sample_rate: int = 16000
    format: str = "s16"


@dataclass
class WhisperConfig:
    url: str = "http://localhost:8178/v1/audio/transcriptions"
    timeout_s: int = 60


@dataclass
class LlmConfig:
    url: str = "http://localhost:8179/v1/chat/completions"
    timeout_s: int = 180


@dataclass
class TranscriptConfig:
    output_dir: Path = field(
        default_factory=lambda: Path.home() / "Vaults/odsod/raw/transcripts"
    )


@dataclass
class DedupConfig:
    threshold: float = 0.6


@dataclass
class SignalsConfig:
    silence_threshold_secs: int = 180
    kwin_poll_interval_secs: int = 10
    meeting_window_patterns: list[str] = field(default_factory=lambda: ["meet.google.com"])


@dataclass
class Config:
    audio: AudioConfig = field(default_factory=AudioConfig)
    whisper: WhisperConfig = field(default_factory=WhisperConfig)
    llm: LlmConfig = field(default_factory=LlmConfig)
    transcript: TranscriptConfig = field(default_factory=TranscriptConfig)
    dedup: DedupConfig = field(default_factory=DedupConfig)
    signals: SignalsConfig = field(default_factory=SignalsConfig)


def _expand_path(s: str) -> Path:
    return Path(s).expanduser()


def load_config() -> Config:
    config_path = Path.home() / ".config/recorder/config.toml"
    if not config_path.exists():
        return Config()

    with open(config_path, "rb") as f:
        raw = tomllib.load(f)

    audio = AudioConfig(**raw.get("audio", {}))
    whisper = WhisperConfig(**raw.get("whisper", {}))
    llm = LlmConfig(**raw.get("llm", {}))

    transcript_raw = raw.get("transcript", {})
    if "output_dir" in transcript_raw:
        transcript_raw["output_dir"] = _expand_path(transcript_raw["output_dir"])
    transcript = TranscriptConfig(**transcript_raw)

    dedup = DedupConfig(**raw.get("dedup", {}))
    signals = SignalsConfig(**raw.get("signals", {}))

    return Config(
        audio=audio,
        whisper=whisper,
        llm=llm,
        transcript=transcript,
        dedup=dedup,
        signals=signals,
    )
