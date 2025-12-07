

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ox_itemlist'
description 'Simple item list viewer using ox_lib'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory'
}