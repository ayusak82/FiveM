fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'サイズ変更薬スクリプト - 小さくなる薬と大きくなる薬'
version '1.0.0'

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
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'qb-core',
    'ox_lib'
}
