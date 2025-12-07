

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Advanced Crafting System with Experience and Multi-Crafting'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js'
}

escrow_ignore {
    'shared/config.lua',
    'web/**'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'ox_inventory'
}