

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description '射撃練習用スクリプト - Shooting Range Training Script'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/shooting.lua'
}

server_scripts {
    'shared/config.lua',
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'okokNotify'
}
