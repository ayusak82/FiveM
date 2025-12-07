

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Thermite Mission Script - Team-based heist mission'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

escrow_ignore {
    'shared/config.lua',
    'README.md'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib'
}
