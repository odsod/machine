from datetime import datetime

from recorder.timeline import ParticipantSet, SpeakerTimeline, WindowTimeline


def t(s: str) -> datetime:
    return datetime.strptime(s, "%H:%M:%S")


class TestSpeakerTimeline:
    def test_single_speaker_in_window(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:00:30"), None)

        assert tl.speakers_in(t("09:00:00"), t("09:00:25")) == ["Alice"]

    def test_multiple_speakers_in_window(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:00:10"), "Bob")
        tl.append(t("09:00:20"), None)

        assert tl.speakers_in(t("09:00:00"), t("09:00:20")) == ["Alice", "Bob"]

    def test_speaker_active_at_start(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:00:30"), "Bob")

        result = tl.speakers_in(t("09:00:10"), t("09:00:35"))
        assert result == ["Alice", "Bob"]

    def test_no_speakers_in_window(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), None)

        assert tl.speakers_in(t("09:00:05"), t("09:00:10")) == []

    def test_speaker_before_window_carries_over(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")

        assert tl.speakers_in(t("09:00:05"), t("09:00:10")) == ["Alice"]

    def test_none_before_window_means_empty(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:00:05"), None)

        assert tl.speakers_in(t("09:00:10"), t("09:00:15")) == []

    def test_dedup_same_speaker(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:00:05"), "Alice")
        tl.append(t("09:00:10"), "Alice")

        assert tl.speakers_in(t("09:00:00"), t("09:00:15")) == ["Alice"]

    def test_eviction(self):
        tl = SpeakerTimeline(max_age_secs=60)
        tl.append(t("09:00:00"), "Alice")
        tl.append(t("09:05:00"), "Bob")

        assert tl.speakers_in(t("09:00:00"), t("09:00:30")) == []
        assert tl.speakers_in(t("09:04:30"), t("09:05:00")) == ["Bob"]

    def test_empty_timeline(self):
        tl = SpeakerTimeline()
        assert tl.speakers_in(t("09:00:00"), t("09:00:10")) == []

    def test_order_by_first_appearance(self):
        tl = SpeakerTimeline()
        tl.append(t("09:00:00"), "Bob")
        tl.append(t("09:00:05"), "Alice")
        tl.append(t("09:00:10"), "Bob")

        result = tl.speakers_in(t("09:00:00"), t("09:00:15"))
        assert result == ["Bob", "Alice"]


class TestParticipantSet:
    def test_initial_update(self):
        ps = ParticipantSet()
        new = ps.update({"Alice", "Bob"})
        assert new == {"Alice", "Bob"}

    def test_no_new_names(self):
        ps = ParticipantSet()
        ps.update({"Alice"})
        assert ps.update({"Alice"}) is None

    def test_incremental_growth(self):
        ps = ParticipantSet()
        ps.update({"Alice"})
        new = ps.update({"Alice", "Bob"})
        assert new == {"Bob"}

    def test_get_all(self):
        ps = ParticipantSet()
        ps.update({"Alice"})
        ps.update({"Bob"})
        assert ps.get_all() == {"Alice", "Bob"}

    def test_reset(self):
        ps = ParticipantSet()
        ps.update({"Alice"})
        ps.reset()
        assert ps.get_all() == set()
        new = ps.update({"Alice"})
        assert new == {"Alice"}


class TestWindowTimeline:
    def test_events_between(self):
        wt = WindowTimeline()
        wt.append(t("09:00:00"), "Meet - Standup", "opened")
        wt.append(t("09:30:00"), "Meet - Standup", "closed")

        events = wt.events_between(t("08:50:00"), t("09:35:00"))
        assert len(events) == 2
        assert events[0].title == "Meet - Standup"
        assert events[0].action == "opened"

    def test_events_between_filters(self):
        wt = WindowTimeline()
        wt.append(t("09:00:00"), "Meet - Standup", "opened")
        wt.append(t("09:30:00"), "Meet - Standup", "closed")

        events = wt.events_between(t("09:10:00"), t("09:25:00"))
        assert len(events) == 0

    def test_current_meeting_open(self):
        wt = WindowTimeline()
        wt.append(t("09:00:00"), "Meet - Standup", "opened")
        assert wt.current_meeting() == "Meet - Standup"

    def test_current_meeting_closed(self):
        wt = WindowTimeline()
        wt.append(t("09:00:00"), "Meet - Standup", "opened")
        wt.append(t("09:30:00"), "Meet - Standup", "closed")
        assert wt.current_meeting() is None

    def test_current_meeting_renamed(self):
        wt = WindowTimeline()
        wt.append(t("09:00:00"), "Meet", "opened")
        wt.append(t("09:01:00"), "Meet - Standup", "renamed")
        assert wt.current_meeting() == "Meet - Standup"
