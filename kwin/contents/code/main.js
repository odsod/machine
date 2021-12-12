function log(...args) {
  console.log("[odsod/desktop]", ...args)
}

[
    {key: "Meta+C", app: "calendar", query: "calendar.google.com"},
    {key: "Meta+U", app: "terminal", query: "terminal"},
    {key: "Meta+H", app: "browser", query: "google-chrome"},
    {key: "Meta+T", app: "passwords", query: "keepassxc"},
    {key: "Meta+G", app: "mail", query: "mail.google.com"},
    {key: "Meta+G", app: "meet", query: "meet.google.com"},
    {key: "Meta+R", app: "run"},
    {key: "Meta+S", app: "slack", query: "einride.slack.com"},
    {key: "Meta+D", app: "spectacle", query: "spectacle"},
    {key: "Meta+.", app: "spotify", query: "spotify"},
    {key: "Meta+L", app: "settings", query: "systemsettings5"},
    {key: "Meta+Z", app: "zoom", query: "zoom"},
].forEach(function(config) {
    log("registering shortcut", config.app)
    registerShortcut("odsod"+config.app, "[odsod] " + config.app, config.key, function() {
        log("handling shortcut", config.app)
        if (config.query) {
            const client = workspace.clientList().find(function(client) {
                return client.resourceName.toString() === config.query;
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
                return
            }
        }
        log("opening", config.app)
        callDBus("io.github.odsod.desktop", "/", "io.github.odsod.desktop.Service", "open_app", config.app)
    })
})
