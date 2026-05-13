"""Extract Google Meet participants via AT-SPI accessibility tree.

Requires Chrome launched with --force-renderer-accessibility.
Requires AT-SPI enabled (gsettings org.gnome.desktop.interface toolkit-accessibility true).
"""

import sys
import sysconfig

# gi (PyGObject) is a system package — ensure it's importable from uv tool venvs
_system_site = sysconfig.get_path("purelib", vars={"base": "/usr", "platbase": "/usr"})
_system_plat = sysconfig.get_path("platlib", vars={"base": "/usr", "platbase": "/usr"})
for _p in (_system_site, _system_plat):
    if _p and _p not in sys.path:
        sys.path.append(_p)

import gi

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi


def get_participants() -> list[str] | None:
    """Extract current Meet participant names.

    Returns list of participant names, or None if Meet is not in a call
    or AT-SPI is unavailable.
    """
    doc = _find_meet_document()
    if doc is None:
        return None

    title = _find_meeting_title(doc)
    count = _get_people_count(doc)
    if count is None:
        return None

    all_static = _collect_static_text(doc)
    participants = _filter_participants(all_static, title)

    if len(participants) == count:
        return participants

    # Count mismatch — return what we found but caller should treat cautiously
    if participants:
        return participants

    return None


def get_meeting_title() -> str | None:
    """Extract current meeting title, or None if not in a call."""
    doc = _find_meet_document()
    if doc is None:
        return None
    return _find_meeting_title(doc)


def _find_meet_document():
    """Find the Meet document web node in Chrome's AT-SPI tree."""
    try:
        desktop = Atspi.get_desktop(0)
    except Exception:
        return None

    for i in range(desktop.get_child_count()):
        app = desktop.get_child_at_index(i)
        if not app:
            continue
        name = app.get_name() or ""
        if "chrome" not in name.lower():
            continue
        doc = _find_node(app, role="document web", name_contains="Meet")
        if doc:
            return doc

    return None


def _find_meeting_title(doc) -> str | None:
    """Extract meeting title from the heading element."""
    heading = _find_node(doc, role="heading")
    if heading:
        return heading.get_name() or None
    return None


def _get_people_count(doc) -> int | None:
    """Extract participant count from the People button."""
    people_btn = _find_node(doc, role="button", name_exact="People")
    if not people_btn:
        return None

    def find_count(node, depth=0):
        if depth > 5:
            return None
        try:
            if node.get_role_name() == "static":
                try:
                    return int(node.get_name())
                except (ValueError, TypeError):
                    pass
            for i in range(node.get_child_count()):
                child = node.get_child_at_index(i)
                if child:
                    result = find_count(child, depth + 1)
                    if result is not None:
                        return result
        except Exception:
            pass
        return None

    return find_count(people_btn)


def _collect_static_text(node, depth=0, max_depth=30) -> list[str]:
    """Collect all static text node values from the tree."""
    results = []
    if depth > max_depth:
        return results
    try:
        if node.get_role_name() == "static" and node.get_name():
            results.append(node.get_name())
        for i in range(min(node.get_child_count(), 200)):
            child = node.get_child_at_index(i)
            if child:
                results.extend(_collect_static_text(child, depth + 1, max_depth))
    except Exception:
        pass
    return results


_KNOWN_UI = frozenset({
    "PM", "AM", "New",
    "Take notes with Gemini", "Ask Gemini",
})


def _filter_participants(texts: list[str], meeting_title: str | None) -> list[str]:
    """Filter static text nodes to likely participant names."""
    seen = set()
    candidates = []
    for text in texts:
        if text in seen:
            continue
        if not _looks_like_name(text, meeting_title):
            continue
        seen.add(text)
        candidates.append(text)

    # Deduplicate: if "Name foo" starts with "Name", keep only "Name"
    participants = []
    for c in candidates:
        if any(c != other and c.startswith(other) for other in candidates):
            continue
        participants.append(c)
    return participants


def _looks_like_name(text: str, meeting_title: str | None) -> bool:
    if not text or len(text) < 2 or len(text) > 80:
        return False
    if meeting_title and text == meeting_title:
        return False
    if text in _KNOWN_UI:
        return False
    if text.isdigit():
        return False
    if ":" in text and len(text) <= 8:
        return False
    if not any(c.isalpha() for c in text):
        return False
    if not text[0].isupper():
        return False
    if len(text) > 50:
        return False
    return True


def _find_node(node, role=None, name_exact=None, name_contains=None, depth=0, max_depth=30):
    """Find first node matching criteria."""
    if depth > max_depth:
        return None
    try:
        node_role = node.get_role_name()
        node_name = node.get_name() or ""
        match = True
        if role and node_role != role:
            match = False
        if name_exact and node_name != name_exact:
            match = False
        if name_contains and name_contains not in node_name:
            match = False
        if match and (role or name_exact or name_contains):
            return node
        for i in range(min(node.get_child_count(), 200)):
            child = node.get_child_at_index(i)
            if child:
                result = _find_node(child, role, name_exact, name_contains, depth + 1, max_depth)
                if result:
                    return result
    except Exception:
        pass
    return None
