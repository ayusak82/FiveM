

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Simple stash creation script using ox_inventory'
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
    'server/main.lua'
}

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql'
}