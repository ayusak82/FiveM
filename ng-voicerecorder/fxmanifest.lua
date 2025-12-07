

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'ng-voicerecorder - Voice Recording System for FiveM'
version '2.0.0'

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

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql',
    'pma-voice'
}