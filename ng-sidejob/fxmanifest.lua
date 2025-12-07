

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'ミニゲームをクリアしておこずかいをもらう内職スクリプト'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/minigame.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/games/typing.js',
    'html/games/color.js',
    'html/games/memory.js',
    'html/games/rhythm.js',
    'html/games/puzzle.js',
    'html/games/racing.js'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib'
}
