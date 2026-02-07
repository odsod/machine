#!/usr/bin/env python3

import dbus
import dbus.service
import dbus.mainloop.glib
import json
import subprocess
import syslog
from gi.repository import GLib

_QT_MODIFIERS = {
    "Meta": 0x10000000,
    "Ctrl": 0x04000000,
    "Alt": 0x08000000,
    "Shift": 0x02000000,
}

_QT_KEYS = {
    "Backspace": 0x01000003,
    "Tab": 0x01000001,
    "Return": 0x01000004,
    "Escape": 0x01000000,
    "Space": 0x20,
    "Delete": 0x01000007,
    "Insert": 0x01000006,
    "Home": 0x01000010,
    "End": 0x01000011,
    "PageUp": 0x01000016,
    "PageDown": 0x01000017,
    "Left": 0x01000012,
    "Up": 0x01000013,
    "Right": 0x01000014,
    "Down": 0x01000015,
    "Print": 0x01000009,
    "Plus": 0x2B,
}
for i in range(1, 13):
    _QT_KEYS[f"F{i}"] = 0x01000030 + i - 1
# Printable ASCII characters map to their Unicode codepoints (uppercased for letters)
for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    _QT_KEYS[c] = ord(c)
for c in "0123456789":
    _QT_KEYS[c] = ord(c)
for c in "-=[]\\;',./`":
    _QT_KEYS[c] = ord(c)


def parse_keysequence(s):
    parts = s.split("+")
    keycode = 0
    for part in parts:
        if part in _QT_MODIFIERS:
            keycode |= _QT_MODIFIERS[part]
        else:
            key = part.upper() if len(part) == 1 and part.isalpha() else part
            if key not in _QT_KEYS:
                raise ValueError(f"Unknown key: {part}")
            keycode |= _QT_KEYS[key]
    return keycode


class Service(dbus.service.Object):
    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        session_bus = dbus.SessionBus()
        bus_name = dbus.service.BusName("io.github.odsod.kwin", session_bus)
        kglobalaccel_obj = session_bus.get_object(
            "org.kde.kglobalaccel", "/kglobalaccel"
        )
        self._kglobalaccel = dbus.Interface(
            kglobalaccel_obj, dbus_interface="org.kde.KGlobalAccel"
        )
        kwin_component_obj = session_bus.get_object(
            "org.kde.kglobalaccel", "/component/kwin"
        )
        self._kwin_component = dbus.Interface(
            kwin_component_obj, dbus_interface="org.kde.kglobalaccel.Component"
        )
        dbus.service.Object.__init__(self, bus_name, "/")
        self._loop = GLib.MainLoop()

    def run_loop(self):
        self._loop.run()

    @dbus.service.method("io.github.odsod.kwin.Service", in_signature="s")
    def run_shortcut(self, payload):
        shortcut = json.loads(payload)
        syslog.syslog("run_shortcut: " + str(shortcut))
        subprocess.Popen(shortcut["command"])

    @dbus.service.method("io.github.odsod.kwin.Service", in_signature="s")
    def log(self, payload):
        syslog.syslog("log: " + payload)

    @dbus.service.method("io.github.odsod.kwin.Service", in_signature="s")
    def configure_shortcuts(self, payload):
        shortcuts = json.loads(payload)
        syslog.syslog("configure_shortcuts: " + str(shortcuts))
        # Delete old shortcuts
        active_names = {shortcut["actionId"][1] for shortcut in shortcuts}
        for name in [
            str(name)
            for name in self._kwin_component.shortcutNames()
            if (name.startswith("odsod") or name.startswith("[odsod]"))
            and name not in active_names
        ]:
            syslog.syslog("unregistering " + name)
            self._kglobalaccel.unregister("kwin", name)
        # Bind current shortcuts
        syslog.syslog("starting shortcut configuration")
        for shortcut in shortcuts:
            syslog.syslog("looking up keycode: " + str(shortcut))
            keycode = parse_keysequence(shortcut["key"])
            syslog.syslog("got keycode: " + str(keycode))
            existing_action_id = self._kglobalaccel.action(keycode)
            if len(existing_action_id) > 0:
                syslog.syslog("unregistering shortcut: " + str(existing_action_id))
                self._kglobalaccel.setForeignShortcut(existing_action_id, [])
            syslog.syslog("registering shortcut: " + str(shortcut["actionId"]))
            self._kglobalaccel.setForeignShortcut(shortcut["actionId"], [keycode])
        syslog.syslog("shortcuts configured successfully")


if __name__ == "__main__":
    syslog.openlog("odsod-kwin-dbus-service")
    syslog.syslog("main")
    Service().run_loop()
