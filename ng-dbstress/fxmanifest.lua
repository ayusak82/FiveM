

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Database Stress Testing Tool - データベース負荷テストツール'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/tests.lua',
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
