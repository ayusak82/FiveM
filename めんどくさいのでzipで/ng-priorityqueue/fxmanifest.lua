fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Priority Queue System with Discord Integration'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}