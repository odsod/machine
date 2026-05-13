import subprocess
from datetime import datetime

from recorder.config import load_config
from recorder.transcript import DailyTranscript

K_DIALOG_COMMAND = [
    "kdialog",
    "--title",
    "Note",
    "--geometry",
    "420",
    "--inputbox",
    "Note:",
]


def note_lines(text: str) -> list[str]:
    return [line.strip() for line in text.splitlines() if line.strip()]


def append_note(lines: list[str]) -> None:
    config = load_config()
    transcript = DailyTranscript(config.transcript.output_dir)
    timestamp = datetime.now().strftime("%H:%M:%S")
    for line in lines:
        transcript.append(timestamp, "\U0001f4dd nfo", line)


def prompt_note() -> str | None:
    result = subprocess.run(
        K_DIALOG_COMMAND,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def main() -> None:
    text = prompt_note()
    if text is None:
        return

    lines = note_lines(text)
    if not lines:
        return

    append_note(lines)


if __name__ == "__main__":
    main()
