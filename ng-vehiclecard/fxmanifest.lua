

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Vehicle Card System - Spawn vehicles with cards'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/ja.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/shop.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/commands.lua',
    'server/starter.lua'
}

escrow_ignore {
    'shared/config.lua',
    'locales/ja.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'ox_inventory'
}
