fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'サブスクリプション管理システム'
version '1.0.2'

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
    'server/discord.lua',
    'server/main.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}

escrow_ignore {
    'shared/config.lua'
}