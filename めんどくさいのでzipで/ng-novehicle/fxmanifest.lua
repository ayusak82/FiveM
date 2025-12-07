fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description '特定の車両への乗車を制限するスクリプト'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib'
}