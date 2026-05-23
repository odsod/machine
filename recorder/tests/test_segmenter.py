"""Tests for the incremental segmenter."""

import tempfile
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

from recorder.config import LlmConfig
from recorder.segmenter import IncrementalSegmenter
from recorder.transcript import DailyTranscript


def t(s: str) -> datetime:
    return datetime.strptime(s, "%H:%M:%S")


def make_segmenter(tmp_path: Path) -> IncrementalSegmenter:
    transcript_dir = tmp_path / "transcripts"
    transcript_dir.mkdir()
    transcript = DailyTranscript(transcript_dir)
    # Touch the file so it exists
    transcript.path
    inbox_dir = tmp_path / "inbox"
    inbox_dir.mkdir()
    llm_config = LlmConfig(url="http://localhost:8179/v1/chat/completions", timeout_s=10)
    logs: list[str] = []
    segmenter = IncrementalSegmenter(
        transcript=transcript,
        llm_config=llm_config,
        inbox_dir=inbox_dir,
        log=logs.append,
    )
    return segmenter


class TestBoundaryDetection:
    def test_silence_triggers_boundary(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")
        seg._last_speech_time = t("09:00:00")

        seg.on_silence(300)
        assert seg._boundary_pending is not None
        assert "silence" in seg._boundary_pending.reason

    def test_silence_below_threshold_no_boundary(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")

        seg.on_silence(299)
        assert seg._boundary_pending is None

    def test_meeting_change_triggers_boundary(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")

        seg.on_meeting_change("Weekly Sync", t("09:30:00"))
        assert seg._boundary_pending is not None
        assert "meeting change" in seg._boundary_pending.reason

    def test_pin_triggers_boundary(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")
        seg.on_speech(t("09:05:00"), "sys", "World")

        seg.on_pin(t("09:06:00"))
        assert seg._boundary_pending is not None
        assert "pin" in seg._boundary_pending.reason


class TestSegmentFinalization:
    @patch("recorder.segmenter.summarize_segment")
    @patch("recorder.segmenter.write_inbox_draft")
    def test_finalize_on_speech_after_boundary(self, mock_write, mock_summarize, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "First segment content")
        seg.on_speech(t("09:05:00"), "sys", "More content")

        seg.on_silence(300)
        assert seg._boundary_pending is not None

        # Speech resumes — should finalize the previous segment
        seg.on_speech(t("09:15:00"), "sys", "New segment starts")

        # Wait for background thread
        for thread in seg._summarize_threads:
            thread.join(timeout=5)

        mock_summarize.assert_called_once()
        segment_arg = mock_summarize.call_args[0][0]
        assert segment_arg.id == "0900"
        speech_events = [e for e in segment_arg.events if e.tag in ("sys", "mic")]
        assert len(speech_events) == 2

    def test_no_finalize_without_boundary(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")
        seg.on_speech(t("09:01:00"), "sys", "World")

        # No boundary pending, so events just accumulate
        assert len(seg._events) == 2
        assert seg._boundary_pending is None

    @patch("recorder.segmenter.summarize_segment")
    @patch("recorder.segmenter.write_inbox_draft")
    def test_flush_finalizes_pending(self, mock_write, mock_summarize, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Content")
        seg.on_speech(t("09:05:00"), "sys", "More")

        seg.flush()
        mock_summarize.assert_called_once()

    @patch("recorder.segmenter.summarize_segment", return_value=None)
    def test_skip_appends_seg_marker(self, mock_summarize, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "Hello")
        seg.on_silence(300)
        seg.on_speech(t("09:10:00"), "sys", "New")

        for thread in seg._summarize_threads:
            thread.join(timeout=5)

        transcript_content = seg._transcript.path.read_text()
        assert "seg" in transcript_content
        assert "skip" in transcript_content


class TestEventAccumulation:
    def test_events_accumulate(self, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "A")
        seg.on_signal(t("09:00:05"), "win", "🪟", "Meet opened")
        seg.on_speech(t("09:00:10"), "sys", "B")

        assert len(seg._events) == 3
        assert len(seg._speech_events) == 2

    @patch("recorder.segmenter.summarize_segment")
    @patch("recorder.segmenter.write_inbox_draft")
    def test_events_reset_after_finalize(self, mock_write, mock_summarize, tmp_path):
        seg = make_segmenter(tmp_path)
        seg.on_speech(t("09:00:00"), "sys", "A")
        seg.on_speech(t("09:01:00"), "sys", "B")
        seg.on_silence(300)
        seg.on_speech(t("09:10:00"), "sys", "C")

        for thread in seg._summarize_threads:
            thread.join(timeout=5)

        # Only the new event should remain
        assert len(seg._events) == 1
        assert seg._events[0].text == "C"
