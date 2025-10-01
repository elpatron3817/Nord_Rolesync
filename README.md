# Nord_Rolesync
## Installation
1. Erstelle einen neuen Ordner in deinem server-data/resources Verzeichnis mit dem Namen "discord_role_sync"
2. Kopiere die Dateien `fxmanifest.lua`, `config.lua` und `server.lua` in diesen Ordner
3. Füge "start discord_role_sync" zu deiner server.cfg hinzu
4. Konfiguriere den Discord Bot Token und die Rollen in der config.lua

## Discord Bot Setup
1. Gehe zu https://discord.com/developers/applications
2. Erstelle eine neue Anwendung
3. Unter dem "Bot" Tab, erstelle einen Bot
4. Kopiere den Bot Token und füge ihn in die config.lua ein
5. Aktiviere unter "Privileged Gateway Intents" die Option "SERVER MEMBERS INTENT"
6. Unter OAuth2 > URL Generator, wähle "bot" und die Berechtigung "Manage Roles"
7. Füge den Bot zu deinem Discord Server hinzu mit dem generierten Link

## Konfiguration
Bearbeite die config.lua:
- Füge deinen Discord Bot Token ein
- Füge deine Discord Server ID ein
- Konfiguriere die Role-Sync Mapping (Discord Role ID = ESX Gruppe)
- Passe das SyncInterval an (Empfohlen: 5-10 Sekunden)

## Features
- Live Synchronisation zwischen Discord Rollen und ESX Gruppen
- Optimierte Performance (0ms im Leerlauf)
- Debug-Modus für einfache Fehlerbehebung
- Sofortige Synchronisation bei Spieler-Login

## Support
Bei Fragen oder Problemen, bitte mich auf Discord kontaktieren oder auf Nord Service Discord ticket auf machen: https://discord.gg/5rV7BJ7nDX.

