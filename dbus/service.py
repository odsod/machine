#!/usr/bin/env python3

import dbus
import dbus.service
import dbus.mainloop.glib
import subprocess
import syslog
from gi.repository import GLib

class Service(dbus.service.Object):
   def __init__(self):
      dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
      session_bus = dbus.SessionBus()
      bus_name = dbus.service.BusName("io.github.odsod.desktop", session_bus)
      kglobalaccel_obj = session_bus.get_object('org.kde.kglobalaccel', '/kglobalaccel')
      self._kglobalaccel = dbus.Interface(kglobalaccel_obj, dbus_interface='org.kde.KGlobalAccel')
      kwin_component_obj = session_bus.get_object('org.kde.kglobalaccel', '/component/kwin') 
      self._kwin_component = dbus.Interface(kwin_component_obj, dbus_interface='org.kde.kglobalaccel.Component')
      dbus.service.Object.__init__(self, bus_name, "/")
      self._loop = GLib.MainLoop()

   def run_loop(self):
        self._loop.run()

   @dbus.service.method("io.github.odsod.desktop.Service", in_signature='s', out_signature='')
   def open_app(self, app):
       syslog.syslog("open "+app)
       if app == 'terminal':
          subprocess.Popen(['urxvtmux', 'terminal'])
       elif app == 'browser':
          subprocess.Popen(['google-chrome'])
       elif app == 'calendar':
          subprocess.Popen(['google-chrome', '--app=https://calendar.google.com'])
       elif app == 'passwords':
          subprocess.Popen(['keepassxc'])
       elif app == 'mail':
           subprocess.Popen(['google-chrome', '--app=https://mail.google.com'])
       elif app == 'meet':
           subprocess.Popen(['google-chrome', '--app=https://meet.google.com'])
       elif app == 'run':
           subprocess.Popen(['rofi', '-show', 'run', '-display-run', '""', '-theme-str', '#window { border: 5; }'])
       elif app == 'slack':
          subprocess.Popen(['google-chrome', '--app=https://einride.slack.com'])
       elif app == 'spectacle':
          subprocess.Popen(['spectacle'])
       elif app == 'spotify':
          subprocess.Popen(['spotify'])
       elif app == 'settings':
          subprocess.Popen(['systemsettings5'])
       elif app == 'zoom':
          subprocess.Popen(['zoom'])

   @dbus.service.method("io.github.odsod.desktop.Service", in_signature='', out_signature='')
   def configure(self):
        syslog.syslog("configure")
        for name in [
            str(name) for name
            in self._kwin_component.shortcutNames()
            if name.startswith('odsod')
        ]:
            syslog.syslog('unregistering ' + name)
            self._kglobalaccel.unregister("kwin", name)

   @dbus.service.method("io.github.odsod.desktop.Service", in_signature='', out_signature='')
   def quit(self):
      self._loop.quit()

if __name__ == "__main__":
   syslog.openlog('service.py')
   syslog.syslog('main')
   Service().run_loop()
