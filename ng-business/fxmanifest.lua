

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Business Management System - Stash, Tray, Crafting, Locker, and Blip Management'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/admin.lua',
    'client/job.lua',
    'client/laser.lua',
    'client/stash.lua',
    'client/tray.lua',
    'client/crafting.lua',
    'client/locker.lua',
    'client/blip.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/job.lua',
    'server/stash.lua',
    'server/tray.lua',
    'server/crafting.lua',
    'server/locker.lua',
    'server/blip.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_inventory',
    'oxmysql'
}
