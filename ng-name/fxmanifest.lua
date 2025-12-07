

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description '名前表示スクリプト'
version '1.1.1'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua',
    'README.md'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}