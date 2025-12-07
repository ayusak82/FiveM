fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Item Creator System for QBX'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

lua54 'yes'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_inventory'
}