fx_version "cerulean"
game "gta5"
lua54 'on'

description 'NCCGr, ng-lootbox'
version '1.0.0'

ui_page 'web/build/index.html'

shared_scripts {
  'init.lua'
}

client_script "client/client.lua"

server_scripts {
  'server/bridge.lua',
  "server/data.lua",
  "server/server.lua"
}

files {
  'web/build/index.html',
  'web/build/assets/*',
}