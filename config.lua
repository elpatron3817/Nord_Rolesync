Config = {}

-- Bot Konfiguration
Config.DiscordBotToken = "DISCORD_BOT_TOKEN"
Config.GuildId = "DISCORD_SERVER_ID"
Config.SyncInterval = 5 -- Sekunden
Config.Debug = false

-- Rollen-Synchronisation
Config.RoleSync = {
    ["1364583459607023666"] = "admin",
    -- Weitere Rollen hier hinzufügen
}

Config.Webhooks = {
    -- Spieler Login Webhook
    login = {
        enabled = true,
        url = "WEBHOOK",
        color = 3066993, -- Grün
        title = "NORD CITY",
        description = "Discord Rolle Geladen",
        botName = "NORD CITY",
        avatarUrl = "https://dein-server.de/logo.png",
        footerText = "",  -- Leer lassen für Standard-Footer
        footerIcon = "https://dein-server.de/icon.png",
        thumbnailUrl = "https://dein-server.de/thumbnail.png",
        authorName = "NORD CITY Spieler-System",
        authorIcon = "https://dein-server.de/author-icon.png",
        includeTimestamp = true,
        useAtPrefix = true, -- @ vor dem Namen
        playerLabel = "Spieler:",
        groupLabel = "⭐Gruppe:",
        jobLabel = "🎯Job:",
        identifiersLabel = "🔍Identifiers:",
        content = ""
    },
    
    -- Rolle hinzugefügt Webhook
    role_added = {
        enabled = true,
        url = "WEBHOOK",
        color = 3447003, -- Blau
        title = "NORD CITY",
        description = "Discord Rolle Hinzugefügt",
        botName = "NORD CITY",
        avatarUrl = "https://dein-server.de/logo.png",
    },
    
    -- Rolle entfernt Webhook
    role_removed = {
        enabled = true,
        url = "WEBHOOK",
        color = 15158332, -- Rot
        title = "NORD CITY",
        description = "Discord Rolle Entfernt",
        botName = "NORD CITY",
        avatarUrl = "https://dein-server.de/logo.png",
    }
}