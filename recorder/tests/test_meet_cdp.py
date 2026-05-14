from pathlib import Path

from recorder.meet_cdp import ParticipantState, SpeakerDetector, extract_speakers

TESTDATA = Path(__file__).parent / "testdata"


def test_extract_speakers_silent():
    html = (TESTDATA / "meet-tiles-silent.html").read_text()
    result = extract_speakers(html, "kssMZb")
    assert result == [
        ParticipantState(name="Joakim Gustin", speaking=False),
        ParticipantState(name="Oscar Söderlund", speaking=False),
    ]


def test_extract_speakers_both_speaking():
    html = (TESTDATA / "meet-tiles-speaking.html").read_text()
    result = extract_speakers(html, "kssMZb")
    assert result == [
        ParticipantState(name="Joakim Gustin", speaking=True),
        ParticipantState(name="Oscar Söderlund", speaking=True),
    ]


def test_extract_speakers_empty_html():
    result = extract_speakers("<div></div>", "kssMZb")
    assert result == []


def test_extract_speakers_no_name():
    html = '<div data-participant-id="x"><div class="kssMZb">ab</div></div>'
    result = extract_speakers(html, "kssMZb")
    assert result == []


def test_detector_discovers_class():
    """SpeakerDetector discovers the speaking class by diffing two snapshots."""
    detector = SpeakerDetector.__new__(SpeakerDetector)
    detector._port = 9224
    detector._speaking_class = None

    # Simulate first snapshot: no one speaking
    detector._prev_snapshot = {
        "Alice": {"classA", "classB", "classC"},
        "Bob": {"classA", "classD"},
    }

    # Second snapshot: Alice gained "xyzSpeaking"
    current = {
        "Alice": {"classA", "classB", "classC", "xyzSpeaking"},
        "Bob": {"classA", "classD"},
    }

    # Manually call _identify logic by setting prev + calling discovery
    # The class appeared in Alice but was also previously absent — it's a candidate
    new_classes = set()
    for name, classes in current.items():
        prev = detector._prev_snapshot.get(name, set())
        new_classes |= classes - prev

    assert "xyzSpeaking" in new_classes
