fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Item sound system'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'xsound'
}