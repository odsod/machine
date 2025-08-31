const shortcuts = [
  {
    actionId: ["kwin", "Window Close", "KWin", "Close Window"],
    kind: "builtin",
    key: "Meta+Backspace",
  },

  {
    actionId: ["kwin", "Window Maximize", "KWin", "Maximize Window"],
    kind: "builtin",
    key: "Meta+-",
  },

  {
    actionId: ["kwin", "Window Quick Tile Bottom", "KWin", "Quick Tile Window to the Bottom"],
    kind: "builtin",
    key: "Meta+j",
  },

  {
    actionId: ["kwin", "Window Quick Tile Top", "KWin", "Quick Tile Window to the Top"],
    kind: "builtin",
    key: "Meta+k",
  },

  {
    actionId: ["kwin", "Window Quick Tile Left", "KWin", "Quick Tile Window to the Left"],
    kind: "builtin",
    key: "Meta+a",
  },

  {
    actionId: ["kwin", "Window Quick Tile Right", "KWin", "Quick Tile Window to the Right"],
    kind: "builtin",
    key: "Meta+o",
  },

  {
    actionId: ["kwin", "ExposeAll", "KWin", "Toggle Present Windows (All desktops)"],
    kind: "builtin",
    key: "Meta+'",
  },

  {
    actionId: ["kwin", "[odsod] run", "KWin", ""],
    key: "Meta+R",
    kind: "command",
    command: ["krunner"],
  },

  {
    actionId: ["kwin", "[odsod] calendar", "KWin", ""],
    key: "Meta+C",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://calendar.google.com",
    ],
    resourceClassIncludes: "calendar.google.com",
  },

  {
    actionId: ["kwin", "[odsod] terminal", "KWin", ""],
    key: "Meta+U",
    kind: "app",
    command: ["ghostty"],
    resourceClass: "com.mitchellh.ghostty",
  },

  {
    actionId: ["kwin", "[odsod] browser", "KWin", ""],
    key: "Meta+H",
    kind: "app",
    command: ["firefox"],
    resourceClass: "org.mozilla.firefox",
  },

  {
    actionId: ["kwin", "[odsod] passwords", "KWin", ""],
    key: "Meta+T",
    kind: "app",
    command: ["keepassxc"],
    resourceClass: "org.keepassxc.KeePassXC",
  },

  {
    actionId: ["kwin", "[odsod] linear", "KWin", ""],
    key: "Meta+I",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://linear.app",
    ],
    resourceClassIncludes: "linear.app",
  },

  {
    actionId: ["kwin", "[odsod] mail", "KWin", ""],
    key: "Meta+F",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://mail.google.com",
    ],
    resourceClassIncludes: "mail.google.com",
  },

  {
    actionId: ["kwin", "[odsod] meet", "KWin", ""],
    key: "Meta+M",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://meet.google.com",
    ],
    resourceClassIncludes: "meet.google.com",
  },

  {
    actionId: ["kwin", "[odsod] slack", "KWin", ""],
    key: "Meta+S",
    kind: "app",
    command: ["slack"],
    resourceClass: "Slack",
  },

  {
    actionId: ["kwin", "[odsod] screenshot", "KWin", ""],
    key: "Meta+D",
    kind: "app",
    command: ["spectacle"],
    resourceClass: "org.kde.spectacle",
  },

  {
    actionId: ["kwin", "[odsod] spotify", "KWin", ""],
    key: "Meta+.",
    kind: "app",
    command: [
      "flatpak",
      "run",
      "com.spotify.Client",
    ],
    resourceClass: "Spotify",
  },

  {
    actionId: ["kwin", "[odsod] settings", "KWin", ""],
    key: "Meta+L",
    kind: "app",
    command: ["systemsettings"],
    resourceClass: "systemsettings",
  },

  {
    actionId: ["kwin", "[odsod] zoom", "KWin", ""],
    key: "Meta+Z",
    kind: "app",
    command: ["zoom"],
    resourceName: "zoom",
  },

  {
    actionId: ["kwin", "[odsod] emojis", "KWin", ""],
    key: "Meta+,",
    kind: "app",
    command: ["plasma-emojier"],
    resourceName: "plasma-emojier",
  },

  {
    actionId: ["kwin", "[odsod] explorer", "KWin", ""],
    key: "Meta+E",
    kind: "app",
    command: ["dolphin"],
    resourceName: "dolphin",
  },

  {
    actionId: ["kwin", "[odsod] chrome", "KWin", ""],
    key: "Meta+G",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
    ],
    resourceClass: "google-chrome",
  },

  {
    actionId: ["kwin", "[odsod] code", "KWin", ""],
    key: "Meta+/",
    kind: "app",
    command: ["zed"],
    resourceClass: "dev.zed.Zed",
  },

  {
    actionId: ["kwin", "[odsod] obsidian", "KWin", ""],
    key: "Meta+V",
    kind: "app",
    command: ["obsidian"],
    resourceName: "obsidian",
  },

  {
    actionId: ["kwin", "[odsod] discord", "KWin", ""],
    key: "Meta+Y",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://discord.com",
    ],
    resourceClassIncludes: "discord.com",
  },

  {
    actionId: ["kwin", "[odsod] debug", "KWin", ""],
    key: "Meta+;",
    kind: "callback",
    callback: function () {
      log("printing debug output");
      workspace.stackingOrder.forEach(function (window) {
        log("resourceName[", window.resourceName, "]", "resourceClass[", window.resourceClass, "]");
      });
    },
  },

  {
    actionId: ["kwin", "[odsod] mullvad-browser", "KWin", ""],
    key: "Meta+b",
    kind: "app",
    command: ["mullvad-browser"],
    resourceClass: "Mullvad Browser",
  },

  {
    actionId: ["kwin", "[odsod] qbittorrent", "KWin", ""],
    key: "Meta+q",
    kind: "app",
    command: ["qbittorrent"],
    resourceName: "qbittorrent",
  },
];

function registerAppShortcut(shortcut) {
  log("registering app shortcut", JSON.stringify(shortcut));
  registerShortcut(
    shortcut.actionId[1],
    shortcut.actionId[3],
    shortcut.key,
    function () {
      log("handling app shortcut", JSON.stringify(shortcut));
      const window = workspace.stackingOrder.find(function (window) {
        if (shortcut.resourceName) {
          return window.resourceName.toString() === shortcut.resourceName;
        } else if (shortcut.resourceClass) {
          return window.resourceClass.toString() === shortcut.resourceClass;
        } else if (shortcut.resourceClassIncludes) {
          return window.resourceClass
            .toString()
            .includes(shortcut.resourceClassIncludes);
        } else {
          return false;
        }
      });
      if (window) {
        if (window.minimized) {
          window.minimized = false;
          workspace.activeWindow = window;
        } else if (workspace.activeWindow != window) {
          workspace.activeWindow = window;
        } else {
          window.minimized = true;
        }
        log("early return");
        return;
      }
      log("starting");
      callDBus(
        "io.github.odsod.kwin",
        "/",
        "io.github.odsod.kwin.Service",
        "run_shortcut",
        JSON.stringify(shortcut),
      );
    },
  );
}

function registerCommandShortcut(shortcut) {
  log("registering command shortcut", JSON.stringify(shortcut));
  registerShortcut(
    shortcut.actionId[1],
    shortcut.actionId[3],
    shortcut.key,
    function () {
      log("handling command shortcut", JSON.stringify(shortcut));
      callDBus(
        "io.github.odsod.kwin",
        "/",
        "io.github.odsod.kwin.Service",
        "run_shortcut",
        JSON.stringify(shortcut),
      );
    },
  );
}

function registerCallbackShortcut(shortcut) {
  log("registering callback shortcut", JSON.stringify(shortcut.actionId));
  registerShortcut(
    shortcut.actionId[1],
    shortcut.actionId[3],
    shortcut.key,
    function () {
      log("handling callback shortcut", JSON.stringify(shortcut.actionId));
      shortcut.callback();
    },
  );
}

function log(...args) {
  callDBus(
    "io.github.odsod.kwin",
    "/",
    "io.github.odsod.kwin.Service",
    "log",
    JSON.stringify(args)
  );
}

shortcuts.forEach(function (shortcut) {
  switch (shortcut.kind) {
    case "app":
      registerAppShortcut(shortcut);
      break;
    case "command":
      registerCommandShortcut(shortcut);
      break;
    case "callback":
      registerCallbackShortcut(shortcut);
      break;
  }
});

callDBus(
  "io.github.odsod.kwin",
  "/",
  "io.github.odsod.kwin.Service",
  "configure_shortcuts",
  JSON.stringify(shortcuts),
  function () {
    log("shortcuts configured");
  },
);
