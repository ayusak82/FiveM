

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'NPC Quiz System - Interactive quiz with multiple choice questions and HTML UI'
version '2.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

escrow_ignore {
    'shared/config.lua',
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}