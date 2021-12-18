#!/usr/bin/env python3

import dbus
import dbus.service
import dbus.mainloop.glib
import json
import subprocess
import syslog
from gi.repository import GLib
from PySide2.QtGui import QKeySequence


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
    def configure_shortcuts(self, payload):
        shortcuts = json.loads(payload)
        syslog.syslog("configure_shortcuts: " + str(shortcuts))
        # Delete old shortcuts
        # for name in [
        # str(name)
        # for name in self._kwin_component.shortcutNames()
        # if name.startswith("odsod")
        # or name.startswith("[odsod]")
        # and name not in {shortcut["name"] for shortcut in shortcuts}
        # ]:
        # syslog.syslog("unregistering " + name)
        # self._kglobalaccel.unregister("kwin", name)
        # Bind current shortcuts
        syslog.syslog("starting shortcut configuration")
        for shortcut in shortcuts:
            syslog.syslog("looking up keycode: " + str(shortcut))
            keycode = QKeySequence.fromString(shortcut["key"])[0]
            syslog.syslog("got keycode: " + str(keycode))
            existing_action_id = self._kglobalaccel.action(keycode)
            if len(existing_action_id) > 0:
                syslog.syslog("unregistering shortcut: " + str(existing_action_id))
                self._kglobalaccel.setForeignShortcut(existing_action_id, [])
            syslog.syslog("registering shortcut: " + str(shortcut["actionId"]))
            self._kglobalaccel.setForeignShortcut(shortcut["actionId"], [keycode])
        syslog.syslog("shortcuts configured successfully")
        self.quit()

    @dbus.service.method("io.github.odsod.kwin.Service")
    def quit(self):
        self._loop.quit()


if __name__ == "__main__":
    syslog.openlog("odsod-kwin-dbus-service")
    syslog.syslog("main")
    Service().run_loop()
