

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'LB-Phone用のリングトーン変更アプリ'
version '1.0.2'

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

lua54 'yes'

file "ui/dist/**/*"

ui_page "ui/dist/index.html"
-- ui_page "http://localhost:3000" -- 開発モード用

dependencies {
    'qb-core',
    'lb-phone',
    'xsound',
    'oxmysql'
}