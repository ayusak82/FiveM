

fx_version 'cerulean'
game 'gta5'

author 'NCCGr'
description 'Engine Sound Tester - Test custom engine sounds with idle, acceleration, and peak states'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

escrow_ignore {
    'shared/config.lua'
}

lua54 'yes'

dependencies {
    'ox_lib'
}
