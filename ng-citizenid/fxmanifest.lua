

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'CitizenID Clipboard Script'
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