from unittest.mock import patch

from recorder.speaker_cdp import (
    MEET_PLATFORM,
    TEAMS_PLATFORM,
    ParticipantState,
    SpeakerDetector,
    find_meeting_tab,
)


class TestFindMeetingTab:
    def test_finds_meet_tab(self):
        tabs = [
            {"url": "https://meet.google.com/abc-def", "type": "page", "webSocketDebuggerUrl": "ws://localhost:9224/x"},
        ]
        with patch("recorder.speaker_cdp.httpx.get") as mock_get:
            mock_get.return_value.json.return_value = tabs
            mock_get.return_value.raise_for_status = lambda: None
            result = find_meeting_tab([9224])
        assert result is not None
        ws_url, platform = result
        assert ws_url == "ws://localhost:9224/x"
        assert platform is MEET_PLATFORM

    def test_finds_teams_tab(self):
        tabs = [
            {"url": "https://teams.microsoft.com/v2/#/call", "type": "page", "webSocketDebuggerUrl": "ws://localhost:9223/y"},
        ]
        with patch("recorder.speaker_cdp.httpx.get") as mock_get:
            mock_get.return_value.json.return_value = tabs
            mock_get.return_value.raise_for_status = lambda: None
            result = find_meeting_tab([9223])
        assert result is not None
        ws_url, platform = result
        assert ws_url == "ws://localhost:9223/y"
        assert platform is TEAMS_PLATFORM

    def test_no_meeting_tab(self):
        tabs = [
            {"url": "https://google.com", "type": "page", "webSocketDebuggerUrl": "ws://localhost:9224/z"},
        ]
        with patch("recorder.speaker_cdp.httpx.get") as mock_get:
            mock_get.return_value.json.return_value = tabs
            mock_get.return_value.raise_for_status = lambda: None
            result = find_meeting_tab([9224, 9223])
        assert result is None

    def test_port_priority(self):
        """First port with a matching tab wins."""
        meet_tabs = [
            {"url": "https://meet.google.com/abc", "type": "page", "webSocketDebuggerUrl": "ws://localhost:9224/m"},
        ]
        teams_tabs = [
            {"url": "https://teams.microsoft.com/call", "type": "page", "webSocketDebuggerUrl": "ws://localhost:9223/t"},
        ]

        def mock_get(url, **kwargs):
            class Resp:
                def raise_for_status(self):
                    pass

                def json(self):
                    if "9224" in url:
                        return meet_tabs
                    return teams_tabs

            return Resp()

        with patch("recorder.speaker_cdp.httpx.get", side_effect=mock_get):
            result = find_meeting_tab([9224, 9223])
        assert result is not None
        _, platform = result
        assert platform is MEET_PLATFORM

    def test_skips_non_page_tabs(self):
        tabs = [
            {"url": "https://meet.google.com/abc", "type": "background_page", "webSocketDebuggerUrl": "ws://x"},
        ]
        with patch("recorder.speaker_cdp.httpx.get") as mock_get:
            mock_get.return_value.json.return_value = tabs
            mock_get.return_value.raise_for_status = lambda: None
            result = find_meeting_tab([9224])
        assert result is None

    def test_connection_failure(self):
        with patch("recorder.speaker_cdp.httpx.get", side_effect=Exception("refused")):
            result = find_meeting_tab([9224, 9223])
        assert result is None


class TestSpeakerDetectorDiscovery:
    def test_discovers_class_from_diff(self):
        detector = SpeakerDetector(ports=[9224])
        detector._active_ws_url = "ws://localhost:9224/x"
        detector._active_platform = MEET_PLATFORM

        detector._prev_snapshot = {
            "Alice Smith": {"classA", "classB", "classC"},
            "Bob Jones": {"classA", "classD"},
        }

        current = {
            "Alice Smith": {"classA", "classB", "classC", "xyzSpeaking"},
            "Bob Jones": {"classA", "classD"},
        }

        changed: set[str] = set()
        for name in current:
            prev = detector._prev_snapshot.get(name, set())
            changed |= (current[name] - prev) | (prev - current[name])

        assert "xyzSpeaking" in changed
        assert min(changed, key=len) == "xyzSpeaking"

    def test_picks_shortest_changed_class(self):
        """When multiple classes change, the shortest one is selected."""
        detector = SpeakerDetector(ports=[9224])
        detector._prev_snapshot = {
            "Alice Smith": {"base"},
        }

        current = {
            "Alice Smith": {"base", "ab", "longClassName"},
        }

        changed: set[str] = set()
        for name in current:
            prev = detector._prev_snapshot.get(name, set())
            changed |= (current[name] - prev) | (prev - current[name])

        assert min(changed, key=len) == "ab"

    def test_cache_reset_on_ws_url_change(self):
        detector = SpeakerDetector(ports=[9224, 9223])
        detector._active_ws_url = "ws://localhost:9224/old"
        detector._active_platform = MEET_PLATFORM
        detector._speaking_class = "cachedClass"
        detector._prev_snapshot = {"Alice Smith": {"a", "b"}}

        with patch("recorder.speaker_cdp.find_meeting_tab") as mock_find:
            mock_find.return_value = ("ws://localhost:9223/new", TEAMS_PLATFORM)
            with patch("recorder.speaker_cdp._cdp_eval") as mock_eval:
                mock_eval.return_value = '[{"name": "Bob Jones", "classes": ["x", "y"]}]'
                detector.poll()

        assert detector._active_ws_url == "ws://localhost:9223/new"
        assert detector._active_platform is TEAMS_PLATFORM
        assert detector._speaking_class is None

    def test_poll_returns_none_when_no_tab(self):
        detector = SpeakerDetector(ports=[9224])
        with patch("recorder.speaker_cdp.find_meeting_tab", return_value=None):
            result = detector.poll()
        assert result is None


class TestSpeakerDetectorCachedPoll:
    def test_uses_cached_class(self):
        detector = SpeakerDetector(ports=[9224])
        detector._active_ws_url = "ws://localhost:9224/x"
        detector._active_platform = TEAMS_PLATFORM
        detector._speaking_class = "speakCls"

        with patch("recorder.speaker_cdp.find_meeting_tab") as mock_find:
            mock_find.return_value = ("ws://localhost:9224/x", TEAMS_PLATFORM)
            with patch("recorder.speaker_cdp._cdp_eval") as mock_eval:
                mock_eval.return_value = '[{"name": "Alice Smith", "speaking": true}, {"name": "Bob Jones", "speaking": false}]'
                result = detector.poll()

        assert result == [
            ParticipantState(name="Alice Smith", speaking=True),
            ParticipantState(name="Bob Jones", speaking=False),
        ]
