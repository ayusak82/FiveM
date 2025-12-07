

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'IAA Heist - Steal classified data from IAA facility and sell to buyers'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

files {
    'html/index.html',
    'html/sounds/alarm.mp3'
}

ui_page 'html/index.html'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target',
    'oxmysql',
    'ox_inventory'
}