fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Advanced teleport system with cooldown, effects and blacklist zones'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/effects.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib'
}