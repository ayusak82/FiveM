

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'ng-hangar-robbery - 飛行場格納庫強盗システム'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
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
    'ps-dispatch'
}