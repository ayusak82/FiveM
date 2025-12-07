

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Recycle Buy - Material Buyback System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/npc.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'okokNotify'
}
