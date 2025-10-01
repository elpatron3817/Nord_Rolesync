ESX = nil
local discordRunning = false
local cachedRoles = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Funktion um Discord API anzufragen
function DiscordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest("https://discordapp.com/api/"..endpoint, function(errorCode, resultData, resultHeaders)
        data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, method, #jsondata > 0 and json.encode(jsondata) or "", {["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. Config.DiscordBotToken})
    
    while data == nil do
        Wait(0)
    end
    
    return data
end

-- Funktion um Discord ID eines Spielers zu bekommen
function GetDiscordId(source)
    local discordId = nil
    local identifiers = GetPlayerIdentifiers(source)
    
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "discord:") then
            discordId = string.gsub(identifier, "discord:", "")
            return discordId
        end
    end
    
    return nil
end

-- Funktion um Discord Username eines Spielers zu bekommen
function GetDiscordUsername(discordId)
    if discordId then
        local endpoint = "users/" .. discordId
        local user = DiscordRequest("GET", endpoint, {})
        
        if user.code == 200 then
            local data = json.decode(user.data)
            return data.username
        else
            if Config.Debug then
                print("^1[Discord Role Sync] Fehler beim Abrufen des Usernames für " .. discordId .. " - Code: " .. user.code .. "^7")
            end
        end
    end
    
    return "Unbekannt"
end

-- Funktion um Discord Rollen eines Spielers zu bekommen
function GetDiscordRoles(discordId)
    if discordId then
        local endpoint = "guilds/" .. Config.GuildId .. "/members/" .. discordId
        local member = DiscordRequest("GET", endpoint, {})
        
        if member.code == 200 then
            local data = json.decode(member.data)
            local roles = data.roles
            return roles
        else
            if Config.Debug then
                print("^1[Discord Role Sync] Fehler beim Abrufen der Rollen für " .. discordId .. " - Code: " .. member.code .. "^7")
            end
        end
    end
    
    return nil
end

function SendPlayerInfoWebhook(source, eventType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local discordId = GetDiscordId(source)
    local discordUsername = "Unbekannt"
    
    if discordId then
        discordUsername = GetDiscordUsername(discordId)
    end
    
    local playerName = GetPlayerName(source)
    local playerId = source
    local playerGroup = xPlayer.getGroup()
    local playerJob = xPlayer.getJob().name
    
    local identifiers = GetPlayerIdentifiers(source)
    local license = "Unbekannt"
    local license2 = "Unbekannt"
    
    for _, id in pairs(identifiers) do
        if string.find(id, "license:") then
            license = string.gsub(id, "license:", "")
        elseif string.find(id, "license2:") then
            license2 = string.gsub(id, "license2:", "")
        end
    end
    
    local currentTime = os.date("%d.%m.%y • %H:%M:%S Uhr")
    
    local webhookConfig = Config.Webhooks.login
    if eventType == "role_removed" and Config.Webhooks.role_removed then
        webhookConfig = Config.Webhooks.role_removed
    elseif eventType == "role_added" and Config.Webhooks.role_added then
        webhookConfig = Config.Webhooks.role_added
    end

    local webhookURL = webhookConfig.url or Config.Webhooks.login.url
    local color = webhookConfig.color or 3066993
    local title = webhookConfig.title or "NORD ARENA"
    local description = webhookConfig.description or "Spieler Geladen"
    local botName = webhookConfig.botName or "NORD ARENA"
    local avatarUrl = webhookConfig.avatarUrl or ""
    local footerText = webhookConfig.footerText or ("© NORD ARENA " .. os.date("%Y") .. " | " .. currentTime)
    local footerIcon = webhookConfig.footerIcon or ""
    local thumbnailUrl = webhookConfig.thumbnailUrl or ""
    local authorName = webhookConfig.authorName or ""
    local authorIcon = webhookConfig.authorIcon or ""
    local includeTimestamp = webhookConfig.includeTimestamp or true
    
    local playerNamePrefix = webhookConfig.useAtPrefix and "@" or ""
    
    local embed = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] = description,
            ["fields"] = {
                {
                    ["name"] = webhookConfig.playerLabel or "Spieler:",
                    ["value"] = playerNamePrefix .. playerName .. " (ID: " .. playerId .. ")",
                    ["inline"] = true
                },
                {
                    ["name"] = webhookConfig.groupLabel or "⭐Gruppe:",
                    ["value"] = playerGroup,
                    ["inline"] = true
                },
                {
                    ["name"] = webhookConfig.jobLabel or "🎯Job:",
                    ["value"] = playerJob,
                    ["inline"] = true
                },
                {
                    ["name"] = webhookConfig.identifiersLabel or "🔍Identifiers:",
                    ["value"] = "```Discord: " .. discordId .. "\nLicense: " .. license .. "\nLicense2: " .. license2 .. "```",
                    ["inline"] = false
                }                
            },
            ["footer"] = {
                ["text"] = footerText,
                ["icon_url"] = footerIcon
            },
            ["thumbnail"] = thumbnailUrl ~= "" and {
                ["url"] = thumbnailUrl
            } or nil,
            ["author"] = authorName ~= "" and {
                ["name"] = authorName,
                ["icon_url"] = authorIcon
            } or nil
        }
    }

    if includeTimestamp then
        embed[1]["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    local webhookData = {
        username = botName,
        avatar_url = avatarUrl,
        embeds = embed
    }

    if webhookConfig.content and webhookConfig.content ~= "" then
        webhookData.content = webhookConfig.content
    end
    
    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode(webhookData), { ['Content-Type'] = 'application/json' })
    
    if Config.Debug then
        print("^2[Discord Role Sync] Webhook gesendet für " .. playerName .. " (" .. discordUsername .. ") - Event: " .. eventType .. "^7")
    end
end

-- Funktion um ESX Gruppen eines Spielers zu aktualisieren
function UpdatePlayerGroups(source, roles)
    if not source or source <= 0 then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        if Config.Debug then
            print("^3[Discord Role Sync] xPlayer nicht gefunden für ID: " .. source .. "^7")
        end
        return 
    end
    
    -- Speicher aktuelle Rollen für Optimierung
    if not cachedRoles[source] then
        cachedRoles[source] = {}
    end
    
    -- Prüfe jede konfigurierte Rolle
    for roleId, groupName in pairs(Config.RoleSync) do
        local hasRole = false
        
        -- Prüfe ob Spieler die Discord Rolle hat
        if roles then
            for _, userRoleId in ipairs(roles) do
                if tostring(userRoleId) == tostring(roleId) then
                    hasRole = true
                    break
                end
            end
        end
        
        -- Wenn Status sich geändert hat, aktualisiere
        if hasRole ~= (cachedRoles[source][roleId] or false) then
            if hasRole then
                -- Füge Gruppe hinzu
                xPlayer.setGroup(groupName)
                if Config.Debug then
                    print("^2[Discord Role Sync] " .. GetPlayerName(source) .. " hat die Gruppe " .. groupName .. " erhalten.^7")
                end
                
                if Config.Webhooks.role_added and Config.Webhooks.role_added.enabled then
                    SendPlayerInfoWebhook(source, "role_added")
                end
            else
                -- Entferne Gruppe (setze auf default 'user')
                if cachedRoles[source][roleId] then
                    xPlayer.setGroup("user")
                    if Config.Debug then
                        print("^1[Discord Role Sync] " .. GetPlayerName(source) .. " hat die Gruppe " .. groupName .. " verloren.^7")
                    end
                    
                    if Config.Webhooks.role_removed and Config.Webhooks.role_removed.enabled then
                        SendPlayerInfoWebhook(source, "role_removed")
                    end
                end
            end
            
            -- Cache aktualisieren
            cachedRoles[source][roleId] = hasRole
        end
    end
end

-- Funktion für die regelmäßige Synchronisation
function SyncDiscordRoles()
    if discordRunning then return end
    discordRunning = true
    
    -- Optimierung: Nur aktive Spieler synchronisieren
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local discordId = GetDiscordId(playerId)
        
        if discordId then
            local roles = GetDiscordRoles(discordId)
            if roles then
                UpdatePlayerGroups(playerId, roles)
            end
        elseif Config.Debug then
            print("^3[Discord Role Sync] Keine Discord ID gefunden für " .. GetPlayerName(playerId) .. "^7")
        end
        
        -- Kurze Pause für Netzwerkoptimierung
        Wait(50)
    end
    
    discordRunning = false
end

-- Hauptschleife für Synchronisation
Citizen.CreateThread(function()
    while true do
        SyncDiscordRoles()
        Citizen.Wait(Config.SyncInterval * 1000)
    end
end)

-- Event für Spieler-Login
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId)
    local source = playerId
    if source then
        if Config.Webhooks.login and Config.Webhooks.login.enabled then
            SendPlayerInfoWebhook(source, "login")
        end
        
        -- Synchronisiere Rollen
        local discordId = GetDiscordId(source)
        if discordId then
            local roles = GetDiscordRoles(discordId)
            if roles then
                UpdatePlayerGroups(source, roles)
            end
        elseif Config.Debug then
            print("^3[Discord Role Sync] Keine Discord ID gefunden für " .. GetPlayerName(source) .. " beim Login^7")
        end
    end
end)

-- Event für Spieler-Disconnect (Cache bereinigen)
AddEventHandler('playerDropped', function()
    local source = source
    if cachedRoles[source] then
        cachedRoles[source] = nil
    end
end)

-- Server-Start Nachricht
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        print('^2[Discord Role Sync] Script gestartet - Synchronisiere Discord Rollen alle ' .. Config.SyncInterval .. ' Sekunden^7')
        
        -- Überprüfe Bot Token und Server ID
        if Config.DiscordBotToken == "DEIN_DISCORD_BOT_TOKEN" or Config.GuildId == "DEINE_SERVER_ID" then
            print('^1[Discord Role Sync] WARNUNG: Bitte konfiguriere den Bot Token und die Server ID in der config.lua!^7')
        else
            -- Teste Discord Verbindung
            local testData = DiscordRequest("GET", "users/@me", {})
            if testData.code ~= 200 then
                print('^1[Discord Role Sync] FEHLER: Verbindung zum Discord Bot fehlgeschlagen. Überprüfe deinen Bot Token!^7')
            else
                local botInfo = json.decode(testData.data)
                print('^2[Discord Role Sync] Verbindung zu Discord Bot hergestellt: ' .. botInfo.username .. '#' .. botInfo.discriminator .. '^7')
            end
        end
    end
end)

-- Optionaler Export für andere Ressourcen
exports('GetPlayerDiscordRoles', function(source)
    local discordId = GetDiscordId(source)
    if discordId then
        return GetDiscordRoles(discordId)
    end
    return nil
end)