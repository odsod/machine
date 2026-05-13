from datetime import datetime
from pathlib import Path


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

    def append_speech(self, timestamp: str, speaker: str, text: str):
        line = f"[{timestamp}] **{speaker}** {text}\n"
        with open(self.path, "a") as f:
            f.write(line)

    def append_split(self, timestamp: str):
        line = f"[{timestamp}] ✂️ split\n"
        with open(self.path, "a") as f:
            f.write(line)

    def append_note(self, timestamp: str, text: str):
        line = f"[{timestamp}] \U0001f4dd {text}\n"
        with open(self.path, "a") as f:
            f.write(line)

    def append_event(self, timestamp: str, emoji: str, text: str):
        line = f"[{timestamp}] {emoji} {text}\n"
        with open(self.path, "a") as f:
            f.write(line)
