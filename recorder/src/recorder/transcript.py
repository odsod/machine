from datetime import datetime
from pathlib import Path


def format_message(tag: str, text: str = "", speakers: list[str] | None = None) -> str:
    emoji, _, name = tag.partition(" ")
    formatted_tag = f"{emoji} **{name}**" if name else f"**{emoji}**"
    if speakers:
        speaker_str = ", ".join(speakers)
        return f"{formatted_tag} [{speaker_str}] {text}".rstrip()
    return f"{formatted_tag} {text}".rstrip()


def format_line(
    timestamp: str, tag: str, text: str = "", speakers: list[str] | None = None
) -> str:
    return f"[{timestamp}] {format_message(tag, text, speakers=speakers)}"


class DailyTranscript:
    """Append-only daily transcript at raw/transcripts/YYYY-MM-DD-recorder.md"""

    def __init__(self, output_dir: Path):
        self.output_dir = output_dir
        self._path: Path | None = None
        self._date: str | None = None

    @property
    def path(self) -> Path:
        today = datetime.now().strftime("%Y-%m-%d")
        if self._date != today:
            self._date = today
            self._path = self.output_dir / f"{today}-recorder.md"
            if not self._path.exists():
                self._init_file()
        return self._path

    def _init_file(self):
        self.output_dir.mkdir(parents=True, exist_ok=True)
        header = f"---\ndate: {self._date}\ntype: recorder-transcript\n---\n\n"
        self._path.write_text(header)

    def append(self, timestamp: str, tag: str, text: str = "", speakers: list[str] | None = None):
        line = f"{format_line(timestamp, tag, text, speakers=speakers)}\n"
        with open(self.path, "a") as f:
            f.write(line)
