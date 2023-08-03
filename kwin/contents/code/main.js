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
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://calendar.google.com",
    ],
    resourceClassIncludes: "calendar.google.com",
  },

  {
    actionId: ["kwin", "[odsod] terminal", "KWin", ""],
    key: "Meta+U",
    kind: "app",
    command: ["konsole"],
    resourceClass: "org.kde.konsole",
  },

  {
    actionId: ["kwin", "[odsod] browser", "KWin", ""],
    key: "Meta+H",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
    ],
    resourceClass: "google-chrome",
  },

  {
    actionId: ["kwin", "[odsod] passwords", "KWin", ""],
    key: "Meta+T",
    kind: "app",
    command: ["keepassxc"],
    resourceName: "keepassxc",
  },

  {
    actionId: ["kwin", "[odsod] notion", "KWin", ""],
    key: "Meta+N",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://notion.so",
    ],
    resourceClassIncludes: "notion.so",
  },

  {
    actionId: ["kwin", "[odsod] mail", "KWin", ""],
    key: "Meta+G",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
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
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://meet.google.com",
    ],
    resourceClassIncludes: "meet.google.com",
  },

  {
    actionId: ["kwin", "[odsod] slack", "KWin", ""],
    key: "Meta+S",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://einride.slack.com",
    ],
    resourceClassIncludes: "einride.slack.com",
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
    resourceName: "systemsettings",
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
    command: ["ibus-ui-emojier-plasma"],
    resourceName: "ibus-ui-emojier-plasma",
  },

  {
    actionId: ["kwin", "[odsod] explorer", "KWin", ""],
    key: "Meta+E",
    kind: "app",
    command: ["dolphin"],
    resourceName: "dolphin",
  },

  {
    actionId: ["kwin", "[odsod] work", "KWin", ""],
    key: "Meta+Y",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://miro.com/app/board/uXjVP44PoOM=/",
    ],
    resourceClassIncludes: "uXjVP44PoOM=",
  },

  {
    actionId: ["kwin", "[odsod] chatgpt", "KWin", ""],
    key: "Meta+F",
    kind: "app",
    command: [
      "google-chrome",
      "--enable-features=UseOzonePlatform",
      "--ozone-platform=wayland",
      "--password-store=basic",
      "--app=https://chat.openai.com/",
    ],
    resourceClassIncludes: "chat.openai.com",
  },

  {
    actionId: ["kwin", "[odsod] code", "KWin", ""],
    key: "Meta+/",
    kind: "app",
    command: [
      "code",
    ],
    resourceName: "code",
  },

  {
    actionId: ["kwin", "[odsod] debug", "KWin", ""],
    key: "Meta+;",
    kind: "callback",
    callback: function () {
      log("printing debug output")
      workspace.clientList().forEach(function (client) {
        log(client.resourceName, client.resourceClass);
      });
    }
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
        } else if (shortcut.resourceClassIncludes) {
          return client.resourceClass
            .toString()
            .includes(shortcut.resourceClassIncludes);
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
