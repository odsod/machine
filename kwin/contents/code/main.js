function log(...args) {
  console.log("odsod/kwin:", ...args);
}

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
    actionId: [
      "kwin",
      "Window Quick Tile Bottom",
      "KWin",
      "Quick Tile Window to the Bottom",
    ],
    kind: "builtin",
    key: "Meta+j",
  },

  {
    actionId: [
      "kwin",
      "Window Quick Tile Top",
      "KWin",
      "Quick Tile Window to the Top",
    ],
    kind: "builtin",
    key: "Meta+k",
  },

  {
    actionId: [
      "kwin",
      "Window Quick Tile Left",
      "KWin",
      "Quick Tile Window to the Left",
    ],
    kind: "builtin",
    key: "Meta+a",
  },

  {
    actionId: [
      "kwin",
      "Window Quick Tile Right",
      "KWin",
      "Quick Tile Window to the Right",
    ],
    kind: "builtin",
    key: "Meta+o",
  },

  {
    actionId: [
      "kwin",
      "ExposeAll",
      "KWin",
      "Toggle Present Windows (All desktops)",
    ],
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
    resourceName: "calendar.google.com",
  },

  {
    actionId: ["kwin", "[odsod] terminal", "KWin", ""],
    key: "Meta+U",
    kind: "app",
    command: ["alacrittymux", "terminal"],
    resourceClass: "terminal",
  },

  {
    actionId: ["kwin", "[odsod] browser", "KWin", ""],
    key: "Meta+H",
    kind: "app",
    command: ["google-chrome", "--password-store=basic"],
    resourceName: "google-chrome",
  },

  {
    actionId: ["kwin", "[odsod] passwords", "KWin", ""],
    key: "Meta+T",
    kind: "app",
    command: ["keepassxc"],
    resourceName: "keepassxc",
  },

  {
    actionId: ["kwin", "[odsod] mail", "KWin", ""],
    key: "Meta+G",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://mail.google.com",
    ],
    resourceName: "mail.google.com",
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
    resourceName: "meet.google.com",
  },

  {
    actionId: ["kwin", "[odsod] slack", "KWin", ""],
    key: "Meta+S",
    kind: "app",
    command: [
      "google-chrome",
      "--password-store=basic",
      "--app=https://einride.slack.com",
    ],
    resourceName: "einride.slack.com",
  },

  {
    actionId: ["kwin", "[odsod] screenshot", "KWin", ""],
    key: "Meta+D",
    kind: "app",
    command: ["spectacle"],
    resourceName: "spectacle",
  },

  {
    actionId: ["kwin", "[odsod] spotify", "KWin", ""],
    key: "Meta+.",
    kind: "app",
    command: ["spotify"],
    resourceName: "spotify",
  },

  {
    actionId: ["kwin", "[odsod] settings", "KWin", ""],
    key: "Meta+L",
    kind: "app",
    command: ["systemsettings5"],
    resourceName: "systemsettings5",
  },

  {
    actionId: ["kwin", "[odsod] zoom", "KWin", ""],
    key: "Meta+Z",
    kind: "app",
    command: ["zoom"],
    resourceName: "zoom",
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
      const client = workspace.clientList().find(function (client) {
        if (shortcut.resourceName) {
          return client.resourceName.toString() === shortcut.resourceName;
        } else if (shortcut.resourceClass) {
          return client.resourceClass.toString() === shortcut.resourceClass;
        } else {
          return false;
        }
      });
      if (client) {
        if (client.minimized) {
          client.minimized = false;
          workspace.activeClient = client;
        } else if (workspace.activeClient != client) {
          workspace.activeClient = client;
        } else {
          client.minimized = true;
        }
        return;
      }
      callDBus(
        "io.github.odsod.kwin",
        "/",
        "io.github.odsod.kwin.Service",
        "run_shortcut",
        JSON.stringify(shortcut)
      );
    }
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
        JSON.stringify(shortcut)
      );
    }
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
  }
);
