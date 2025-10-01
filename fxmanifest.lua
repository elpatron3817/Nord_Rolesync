fx_version 'cerulean'
game 'gta5'

name 'Discord Role Sync'
description 'Synchronisiert Discord Rollen mit ESX Gruppen'
author 'elpatron3817'
version '1.0.0'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'config.lua',
    'server.lua'
}

dependencies {
    'es_extended'
}